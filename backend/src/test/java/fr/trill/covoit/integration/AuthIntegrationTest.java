package fr.trill.covoit.integration;

import fr.trill.covoit.dto.LoginRequest;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.service.EmailService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean(enforceOverride = true)
    private EmailService emailService;

    @Test
    @DisplayName("Un compte vérifié peut se connecter avec le bon mot de passe")
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
        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(user.getUserId()))
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.emailVerified").value(true))
                .andExpect(jsonPath("$.message").value("Connexion réussie."));
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
}
