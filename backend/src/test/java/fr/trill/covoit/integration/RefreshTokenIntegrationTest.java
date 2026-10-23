package fr.trill.covoit.integration;

import fr.trill.covoit.dto.AuthResponse;
import fr.trill.covoit.dto.LoginRequest;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.model.AuthSession;
import fr.trill.covoit.model.RefreshToken;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.repository.AuthSessionRepository;
import fr.trill.covoit.repository.RefreshTokenRepository;
import fr.trill.covoit.service.EmailService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HexFormat;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:refresh-testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL"
})
@AutoConfigureMockMvc
// Chaque requête garde sa propre transaction pour vérifier que la révocation persiste après un refus.
class RefreshTokenIntegrationTest {

    private static final String PASSWORD = "MotDePasse123!";
    private static final Duration REFRESH_TTL = Duration.ofDays(30);

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private AuthSessionRepository authSessionRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtDecoder jwtDecoder;

    @MockitoBean(enforceOverride = true)
    private EmailService emailService;

    @MockitoBean(enforceOverride = true)
    private Clock clock;

    private Instant testStartTime;

    @BeforeEach
    void setUpClock() {
        // Les secondes entières évitent les écarts de précision dans les dates comparées.
        testStartTime = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        when(clock.instant()).thenReturn(testStartTime);
    }

    @AfterEach
    void cleanDatabase() {
        // Les tokens référencent les sessions, qui référencent les utilisateurs.
        // Cet ordre de suppression respecte les clés étrangères.
        refreshTokenRepository.deleteAllInBatch();
        authSessionRepository.deleteAllInBatch();
        userRepository.deleteAllInBatch();
    }

    @Test
    @DisplayName("Les rotations prolongent la même session, même après ses 30 premiers jours")
    void refresh_WithValidToken_RotatesAndExtendsSession() throws Exception {
        AppUser user = createVerifiedUser();
        AuthResponse loginResponse = loginAndReadResponse(user);
        String originalRefreshToken = loginResponse.getRefreshToken();
        Long expectedSessionId = findStoredRefreshToken(originalRefreshToken).getSessionId();

        // Le renouvellement à J20 doit repousser l'expiration de la session à J50.
        Instant firstRefreshTime = testStartTime.plus(Duration.ofDays(20));
        when(clock.instant()).thenReturn(firstRefreshTime);

        JsonNode firstRefreshResponse = refreshAndExpectSuccess(originalRefreshToken);
        assertRefreshTokenRotation(originalRefreshToken, firstRefreshResponse,
                expectedSessionId, user.getUserId(), firstRefreshTime);

        // À J40, les trente jours depuis le login sont dépassés.
        // La prolongation précédente doit permettre un nouveau renouvellement.
        Instant secondRefreshTime = testStartTime.plus(Duration.ofDays(40));
        when(clock.instant()).thenReturn(secondRefreshTime);

        String replacementRefreshToken = firstRefreshResponse.get("refreshToken").asString();
        JsonNode secondRefreshResponse = refreshAndExpectSuccess(replacementRefreshToken);
        assertRefreshTokenRotation(replacementRefreshToken, secondRefreshResponse,
                expectedSessionId, user.getUserId(), secondRefreshTime);

        assertThat(authSessionRepository.count()).isEqualTo(1);
        assertThat(refreshTokenRepository.count()).isEqualTo(3);
    }

    @Test
    @DisplayName("Un refresh token inconnu est refusé sans créer de session ni de token")
    void refresh_WithUnknownToken_Returns401() throws Exception {
        refreshAndExpectUnauthorized("refresh-token-inconnu");

        assertThat(authSessionRepository.count()).isZero();
        assertThat(refreshTokenRepository.count()).isZero();
    }

    @Test
    @DisplayName("Un refresh token expiré est refusé sans rotation")
    void refresh_WithExpiredToken_Returns401() throws Exception {
        AuthResponse loginResponse = loginAndReadResponse(createVerifiedUser());
        RefreshToken storedRefreshToken = findStoredRefreshToken(loginResponse.getRefreshToken());
        AuthSession session = authSessionRepository.findById(storedRefreshToken.getSessionId()).orElseThrow();

        // À l'instant exact de son échéance, la session est déjà expirée.
        when(clock.instant()).thenReturn(session.getExpiresAt());

        refreshAndExpectUnauthorized(loginResponse.getRefreshToken());

        assertThat(refreshTokenRepository.findById(storedRefreshToken.getTokenId()).orElseThrow().getUsedAt())
                .isNull();
        AuthSession unchangedSession = authSessionRepository.findById(session.getSessionId()).orElseThrow();
        assertThat(unchangedSession.getExpiresAt()).isEqualTo(session.getExpiresAt());
        assertThat(unchangedSession.getRevokedAt()).isNull();
        assertThat(refreshTokenRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("Réutiliser un ancien token révoque sa session sans affecter l'autre connexion")
    void refresh_WithUsedToken_CommitsRevocationForItsSessionOnly() throws Exception {
        AppUser user = createVerifiedUser();
        // Deux logins du même compte représentent deux connexions indépendantes.
        AuthResponse firstLoginResponse = loginAndReadResponse(user);
        AuthResponse secondLoginResponse = loginAndReadResponse(user);

        Long firstSessionId = findStoredRefreshToken(firstLoginResponse.getRefreshToken()).getSessionId();
        Long secondSessionId = findStoredRefreshToken(secondLoginResponse.getRefreshToken()).getSessionId();
        assertThat(secondSessionId).isNotEqualTo(firstSessionId);

        JsonNode refreshResponse = refreshAndExpectSuccess(firstLoginResponse.getRefreshToken());
        String replacementRefreshToken = refreshResponse.get("refreshToken").asString();

        refreshAndExpectUnauthorized(firstLoginResponse.getRefreshToken());

        // On relit la base après le refus pour vérifier que la révocation a été conservée.
        AuthSession revokedSession = authSessionRepository.findById(firstSessionId).orElseThrow();
        assertThat(revokedSession.getRevokedAt()).isEqualTo(testStartTime);
        refreshAndExpectUnauthorized(replacementRefreshToken);

        JsonNode otherSessionRefreshResponse = refreshAndExpectSuccess(secondLoginResponse.getRefreshToken());
        assertThat(jwtDecoder.decode(otherSessionRefreshResponse.get("accessToken").asString()).getSubject())
                .isEqualTo(user.getUserId().toString());
        assertThat(authSessionRepository.findById(secondSessionId).orElseThrow().getRevokedAt()).isNull();
    }

    @Test
    @DisplayName("Un refresh token vide produit une erreur de validation")
    void refresh_WithBlankToken_Returns400() throws Exception {
        sendRefreshRequest("")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.refreshToken")
                        .value("Le refresh token est obligatoire."));

        assertThat(authSessionRepository.count()).isZero();
        assertThat(refreshTokenRepository.count()).isZero();
    }

    private AppUser createVerifiedUser() {
        return userRepository.saveAndFlush(AppUser.builder()
                .email("refresh@univ-tlse3.fr")
                .passwordHash(passwordEncoder.encode(PASSWORD))
                .emailVerified(true)
                .termsAccepted(true)
                .build());
    }

    private AuthResponse loginAndReadResponse(AppUser user) throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email(user.getEmail())
                .password(PASSWORD)
                .build();

        MvcResult result = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        return objectMapper.readValue(result.getResponse().getContentAsString(), AuthResponse.class);
    }

    private ResultActions sendRefreshRequest(String refreshToken) throws Exception {
        return mockMvc.perform(post("/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("refreshToken", refreshToken))));
    }

    private JsonNode refreshAndExpectSuccess(String refreshToken) throws Exception {
        MvcResult result = sendRefreshRequest(refreshToken)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andReturn();

        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private void refreshAndExpectUnauthorized(String refreshToken) throws Exception {
        sendRefreshRequest(refreshToken)
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_REFRESH_TOKEN"))
                .andExpect(jsonPath("$.message")
                        .value("La session est invalide ou a expiré. Veuillez vous reconnecter."));
    }

    private RefreshToken findStoredRefreshToken(String rawRefreshToken) throws NoSuchAlgorithmException {
        // La base conserve seulement l'empreinte du secret reçu.
        // On la recalcule pour retrouver l'enregistrement correspondant.
        byte[] hash = MessageDigest.getInstance("SHA-256")
                .digest(rawRefreshToken.getBytes(StandardCharsets.UTF_8));
        return refreshTokenRepository.findByTokenHash(HexFormat.of().formatHex(hash)).orElseThrow();
    }

    private void assertRefreshTokenRotation(String previousRefreshToken, JsonNode refreshResponse,
                                            Long expectedSessionId, Long expectedUserId,
                                            Instant refreshTime) throws NoSuchAlgorithmException {
        String nextRefreshToken = refreshResponse.get("refreshToken").asString();
        assertThat(nextRefreshToken).isNotEqualTo(previousRefreshToken);

        // L'ancien token reste en base pour reconnaître une éventuelle réutilisation.
        assertThat(findStoredRefreshToken(previousRefreshToken).getUsedAt()).isEqualTo(refreshTime);

        RefreshToken storedNextRefreshToken = findStoredRefreshToken(nextRefreshToken);
        assertThat(storedNextRefreshToken.getSessionId()).isEqualTo(expectedSessionId);
        assertThat(storedNextRefreshToken.getUsedAt()).isNull();
        assertThat(refreshTokenRepository.findByTokenHash(nextRefreshToken)).isEmpty();

        AuthSession updatedSession = authSessionRepository.findById(expectedSessionId).orElseThrow();
        assertThat(updatedSession.getUserId()).isEqualTo(expectedUserId);
        assertThat(updatedSession.getExpiresAt()).isEqualTo(refreshTime.plus(REFRESH_TTL));
        assertThat(updatedSession.getRevokedAt()).isNull();

        Jwt newAccessToken = jwtDecoder.decode(refreshResponse.get("accessToken").asString());
        assertThat(newAccessToken.getSubject()).isEqualTo(expectedUserId.toString());
        assertThat(newAccessToken.getIssuedAt()).isEqualTo(refreshTime);
        assertThat(newAccessToken.getExpiresAt()).isEqualTo(refreshTime.plus(Duration.ofMinutes(15)));
    }
}
