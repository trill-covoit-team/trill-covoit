package fr.trill.covoit.controller;

import tools.jackson.databind.ObjectMapper;
import fr.trill.covoit.dto.AuthResponse;
import fr.trill.covoit.dto.LoginRequest;
import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.RegisterRequest;
import fr.trill.covoit.dto.VerifyEmailRequest;
import fr.trill.covoit.exception.AuthExceptionHandler;
import fr.trill.covoit.exception.EmailAlreadyUsedException;
import fr.trill.covoit.exception.EmailNotVerifiedException;
import fr.trill.covoit.exception.InvalidCredentialsException;
import fr.trill.covoit.exception.InvalidVerificationCodeException;
import fr.trill.covoit.service.AuthService;
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

    private RegisterRequest validRegisterRequest;
    private VerifyEmailRequest validVerifyEmailRequest;
    private LoginRequest validLoginRequest;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(authController)
                .setControllerAdvice(new AuthExceptionHandler())
                .build();

        validRegisterRequest = RegisterRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("MotDePasse123!")
                .termsAccepted(true)
                .build();

        validVerifyEmailRequest = VerifyEmailRequest.builder()
                .email("test@univ-tlse3.fr")
                .code("123456")
                .build();

        validLoginRequest = LoginRequest.builder()
                .email("test@univ-tlse3.fr")
                .password("MotDePasse123!")
                .build();
    }

    @Test
    void register_Success_Returns201() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn(new MessageResponse("Votre compte a été créé. Un code vous a été envoyé."));

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRegisterRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value("Votre compte a été créé. Un code vous a été envoyé."));
    }

    @Test
    void register_InvalidEmail_Returns400() throws Exception {
        validRegisterRequest.setEmail("invalid-email");

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRegisterRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.email").value("L'adresse email est invalide."));
    }

    @Test
    void register_ShortPassword_Returns400() throws Exception {
        validRegisterRequest.setPassword("short");

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRegisterRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.password").value("Le mot de passe doit contenir au moins 8 caractères."));
    }

    @Test
    void register_PasswordExceeds72Bytes_Returns400() throws Exception {
        validRegisterRequest.setPassword("A".repeat(73));

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRegisterRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.password").value("Le mot de passe est trop long."));
    }

    @Test
    void register_EmailAlreadyUsed_Returns409() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new EmailAlreadyUsedException());

        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRegisterRequest)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("EMAIL_ALREADY_USED"))
                .andExpect(jsonPath("$.message").value("Cette adresse email est déjà utilisée."));
    }

    @Test
    void verifyEmail_Success_Returns200() throws Exception {
        when(authService.verifyEmail(any(VerifyEmailRequest.class)))
                .thenReturn(new MessageResponse("Votre adresse email a été validée avec succès."));

        mockMvc.perform(post("/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validVerifyEmailRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Votre adresse email a été validée avec succès."));
    }

    @Test
    void verifyEmail_InvalidCode_Returns400() throws Exception {
        when(authService.verifyEmail(any(VerifyEmailRequest.class)))
                .thenThrow(new InvalidVerificationCodeException());

        mockMvc.perform(post("/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validVerifyEmailRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_VERIFICATION_CODE"))
                .andExpect(jsonPath("$.message").value("Le code de validation est invalide ou expiré."));
    }

    @Test
    void login_Success_Returns200() throws Exception {
        AuthResponse response = AuthResponse.builder()
                .userId(1L)
                .email("test@univ-tlse3.fr")
                .emailVerified(true)
                .message("Connexion réussie.")
                .build();

        when(authService.login(any(LoginRequest.class))).thenReturn(response);

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validLoginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(1L))
                .andExpect(jsonPath("$.email").value("test@univ-tlse3.fr"))
                .andExpect(jsonPath("$.emailVerified").value(true));
    }

    @Test
    void login_InvalidCredentials_Returns401() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new InvalidCredentialsException());

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validLoginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"))
                .andExpect(jsonPath("$.message").value("L'adresse email ou le mot de passe est incorrect."));
    }

    @Test
    void login_EmailNotVerified_Returns403() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new EmailNotVerifiedException());

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validLoginRequest)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("EMAIL_NOT_VERIFIED"))
                .andExpect(jsonPath("$.message").value("Veuillez valider votre adresse email avant de vous connecter."));
    }
}
