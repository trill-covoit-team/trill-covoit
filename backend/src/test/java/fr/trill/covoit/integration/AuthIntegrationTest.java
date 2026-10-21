package fr.trill.covoit.integration;

import fr.trill.covoit.dto.AuthResponse;
import fr.trill.covoit.dto.LoginRequest;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.service.EmailService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import tools.jackson.databind.ObjectMapper;

import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@Import(AuthIntegrationTest.ProtectedEndpointConfiguration.class)
class AuthIntegrationTest {

    private static final String PROTECTED_ENDPOINT = "/test/protected";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtEncoder jwtEncoder;

    @Value("${app.jwt.issuer}")
    private String jwtIssuer;

    @Value("${app.jwt.audience}")
    private String jwtAudience;

    @MockitoBean(enforceOverride = true)
    private EmailService emailService;

    @Test
    @DisplayName("Un compte vérifié reçoit un access token utilisable sur une route protégée")
    void login_WithValidCredentialsAndVerifiedEmail_Returns200() throws Exception {
        String email = "etudiant@univ-tlse3.fr";
        String password = "MotDePasse123!";

        // Préparer le compte dans H2 avec le vrai encodeur de l'application.
        AppUser user = userRepository.saveAndFlush(AppUser.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .emailVerified(true)
                .termsAccepted(true)
                .build());

        LoginRequest request = LoginRequest.builder()
                .email(email)
                .password(password)
                .build();

        // Exécuter le login avec les vrais filtres, services et accès à la base.
        MvcResult result = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(user.getUserId()))
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.emailVerified").value(true))
                .andExpect(jsonPath("$.message").value("Connexion réussie."))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andReturn();

        AuthResponse response = objectMapper.readValue(
                result.getResponse().getContentAsString(), AuthResponse.class);

        mockMvc.perform(get(PROTECTED_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + response.getAccessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(user.getUserId()));
    }

    @Test
    @DisplayName("Un compte vérifié est refusé lorsque le mot de passe est incorrect")
    void login_WithWrongPassword_Returns401() throws Exception {
        String email = "etudiant@univ-tlse3.fr";
        String password = "MotDePasse123!";

        userRepository.saveAndFlush(AppUser.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .emailVerified(true)
                .termsAccepted(true)
                .build());

        LoginRequest request = LoginRequest.builder()
                .email(email)
                .password("MauvaisMotDePasse")
                .build();

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"))
                .andExpect(jsonPath("$.message")
                        .value("L'adresse email ou le mot de passe est incorrect."));
    }

    @Test
    @DisplayName("Un compte dont l'email n'est pas validé est refusé malgré le bon mot de passe")
    void login_WithValidCredentialsAndUnverifiedEmail_Returns403() throws Exception {
        String email = "etudiant@univ-tlse3.fr";
        String password = "MotDePasse123!";

        userRepository.saveAndFlush(AppUser.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .emailVerified(false)
                .termsAccepted(true)
                .build());

        LoginRequest request = LoginRequest.builder()
                .email(email)
                .password(password)
                .build();

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("EMAIL_NOT_VERIFIED"))
                .andExpect(jsonPath("$.message")
                        .value("Veuillez valider votre adresse email avant de vous connecter."));
    }

    @Test
    @DisplayName("Un mauvais mot de passe est refusé avant de signaler que l'email n'est pas validé")
    void login_WithWrongPasswordAndUnverifiedEmail_Returns401() throws Exception {
        String email = "etudiant@univ-tlse3.fr";
        String password = "MotDePasse123!";

        userRepository.saveAndFlush(AppUser.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .emailVerified(false)
                .termsAccepted(true)
                .build());

        LoginRequest request = LoginRequest.builder()
                .email(email)
                .password("MauvaisMotDePasse")
                .build();

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"))
                .andExpect(jsonPath("$.message")
                        .value("L'adresse email ou le mot de passe est incorrect."));
    }

    @Test
    @DisplayName("Une route protégée refuse une requête sans access token")
    void protectedRoute_WithoutToken_Returns401() throws Exception {
        mockMvc.perform(get(PROTECTED_ENDPOINT))
                .andExpect(status().isUnauthorized());
    }

    @ParameterizedTest(name = "{0}")
    @EnumSource(InvalidToken.class)
    @DisplayName("Une route protégée refuse un JWT invalide")
    void protectedRoute_WithInvalidToken_Returns401(InvalidToken invalidToken) throws Exception {
        String accessToken = createInvalidAccessToken(invalidToken);

        mockMvc.perform(get(PROTECTED_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isUnauthorized());
    }

    private String createInvalidAccessToken(InvalidToken invalidToken) {
        Instant now = Instant.now();
        JwtClaimsSet.Builder claims = JwtClaimsSet.builder()
                .issuer(jwtIssuer)
                .audience(List.of(jwtAudience))
                .subject("42")
                .issuedAt(now)
                .expiresAt(now.plus(Duration.ofMinutes(15)));
        JwtEncoder encoder = jwtEncoder;

        // Chaque cas ne modifie qu'une propriété d'un token autrement valide.
        switch (invalidToken) {
            case EXPIRED -> claims
                    .issuedAt(now.minus(Duration.ofMinutes(20)))
                    .expiresAt(now.minus(Duration.ofMinutes(5)));
            case WRONG_SIGNING_KEY -> {
                SecretKeySpec otherKey = new SecretKeySpec(
                        "98765432109876543210987654321098".getBytes(StandardCharsets.UTF_8),
                        "HmacSHA256");
                encoder = NimbusJwtEncoder.withSecretKey(otherKey)
                        .algorithm(MacAlgorithm.HS256)
                        .build();
            }
            case WRONG_ISSUER -> claims.issuer("another-issuer");
            case WRONG_AUDIENCE -> claims.audience(List.of("another-api"));
            case MISSING_EXPIRATION -> claims.claims(values -> values.remove("exp"));
            case MISSING_SUBJECT -> claims.claims(values -> values.remove("sub"));
        }

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256)
                .type("JWT")
                .build();

        return encoder.encode(JwtEncoderParameters.from(header, claims.build()))
                .getTokenValue();
    }

    private enum InvalidToken {
        EXPIRED,
        WRONG_SIGNING_KEY,
        WRONG_ISSUER,
        WRONG_AUDIENCE,
        MISSING_EXPIRATION,
        MISSING_SUBJECT
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class ProtectedEndpointConfiguration {

        @Bean
        ProtectedEndpointController protectedEndpointController() {
            return new ProtectedEndpointController();
        }
    }

    // Ce contrôleur n'existe que dans le contexte de ce test.
    @RestController
    static class ProtectedEndpointController {

        @GetMapping(PROTECTED_ENDPOINT)
        public Map<String, Long> currentUser(@AuthenticationPrincipal Jwt jwt) {
            return Map.of("userId", Long.valueOf(jwt.getSubject()));
        }
    }
}
