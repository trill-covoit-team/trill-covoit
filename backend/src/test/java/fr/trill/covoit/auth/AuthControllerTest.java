package fr.trill.covoit.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.trill.covoit.auth.dto.AuthResponse;
import fr.trill.covoit.auth.dto.LoginRequest;
import fr.trill.covoit.auth.dto.MessageResponse;
import fr.trill.covoit.auth.dto.RegisterRequest;
import fr.trill.covoit.auth.dto.VerifyEmailRequest;
import fr.trill.covoit.auth.exception.AuthExceptionHandler;
import fr.trill.covoit.auth.exception.EmailAlreadyUsedException;
import fr.trill.covoit.auth.exception.EmailNotVerifiedException;
import fr.trill.covoit.auth.exception.InvalidCredentialsException;
import fr.trill.covoit.auth.exception.InvalidVerificationCodeException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private AuthService authService;

    @InjectMocks
    private AuthController authController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(authController)
                .setControllerAdvice(new AuthExceptionHandler())
                .build();
    }

    @Test
    void register_ShouldReturn201_WhenPayloadIsValid() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("supersecret123")
                .termsAccepted(true)
                .build();

        MessageResponse response = MessageResponse.builder()
                .message("Inscription réussie. Un code de validation vous a été envoyé par email.")
                .build();

        when(authService.register(any(RegisterRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value(response.getMessage()));
    }

    @Test
    void register_ShouldReturn400_WhenPasswordIsTooShort() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("court")
                .termsAccepted(true)
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.password").exists());
    }

    @Test
    void register_ShouldReturn400_WhenTermsAreNotAccepted() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("motdepasse123")
                .termsAccepted(false)
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.termsAccepted").exists());
    }

    @Test
    void register_ShouldReturn409_WhenEmailIsAlreadyUsed() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("existant@univ-tlse3.fr")
                .password("motdepasse123")
                .termsAccepted(true)
                .build();

        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new EmailAlreadyUsedException("Cet email est déjà utilisé"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Cet email est déjà utilisé"));
    }

    @Test
    void verifyEmail_ShouldReturn200_WhenCodeIsValid() throws Exception {
        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("test@univ-tlse3.fr")
                .code("123456")
                .build();

        MessageResponse response = MessageResponse.builder()
                .message("Adresse email validée avec succès. Vous pouvez maintenant vous connecter.")
                .build();

        when(authService.verifyEmail(any(VerifyEmailRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value(response.getMessage()));
    }

    @Test
    void verifyEmail_ShouldReturn400_WhenCodeIsInvalidOrExpired() throws Exception {
        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("test@univ-tlse3.fr")
                .code("123456")
                .build();

        when(authService.verifyEmail(any(VerifyEmailRequest.class)))
                .thenThrow(new InvalidVerificationCodeException("Code de validation invalide ou expiré"));

        mockMvc.perform(post("/api/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Code de validation invalide ou expiré"));
    }

    @Test
    void login_ShouldReturn200_WhenCredentialsAreValidAndVerified() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("motdepasse123")
                .build();

        AuthResponse response = AuthResponse.builder()
                .id(1L)
                .email("test@univ-tlse3.fr")
                .role("USER")
                .emailVerified(true)
                .message("Connexion réussie")
                .build();

        when(authService.login(any(LoginRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1L))
                .andExpect(jsonPath("$.email").value("test@univ-tlse3.fr"))
                .andExpect(jsonPath("$.emailVerified").value(true));
    }

    @Test
    void login_ShouldReturn401_WhenCredentialsAreInvalid() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("mauvaismdp")
                .build();

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new InvalidCredentialsException("Identifiants invalides"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Identifiants invalides"));
    }

    @Test
    void login_ShouldReturn403_WhenEmailIsNotVerified() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("motdepasse123")
                .build();

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new EmailNotVerifiedException("Veuillez valider votre adresse email avant de vous connecter"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Veuillez valider votre adresse email avant de vous connecter"));
    }
}
