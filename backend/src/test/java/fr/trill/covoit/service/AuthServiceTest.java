package fr.trill.covoit.service;

import fr.trill.covoit.dto.AuthResponse;
import fr.trill.covoit.dto.LoginRequest;
import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.RegisterRequest;
import fr.trill.covoit.dto.VerifyEmailRequest;
import fr.trill.covoit.exception.EmailAlreadyUsedException;
import fr.trill.covoit.exception.EmailNotVerifiedException;
import fr.trill.covoit.exception.InvalidCredentialsException;
import fr.trill.covoit.exception.InvalidVerificationCodeException;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private AppUserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private AuthService authService;

    private RegisterRequest validRegisterRequest;
    private AppUser sampleUser;

    @BeforeEach
    void setUp() {
        validRegisterRequest = RegisterRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("MotDePasse123!")
                .termsAccepted(true)
                .build();

        sampleUser = AppUser.builder()
                .userId(1L)
                .email("etudiant@univ-tlse3.fr")
                .passwordHash("hashed_password")
                .emailVerified(false)
                .termsAccepted(true)
                .verificationCode("123456")
                .verificationCodeExpiresAt(Instant.now().plus(Duration.ofMinutes(15)))
                .build();
    }

    @Test
    void register_Success() {
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed_password");
        when(userRepository.save(any(AppUser.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MessageResponse response = authService.register(validRegisterRequest);

        assertThat(response).isNotNull();
        assertThat(response.getMessage()).contains("Un code de validation vous a été envoyé par email");

        ArgumentCaptor<AppUser> userCaptor = ArgumentCaptor.forClass(AppUser.class);
        verify(userRepository).save(userCaptor.capture());
        AppUser savedUser = userCaptor.getValue();

        assertThat(savedUser.getEmail()).isEqualTo("etudiant@univ-tlse3.fr");
        assertThat(savedUser.getPasswordHash()).isEqualTo("hashed_password");
        assertThat(savedUser.isEmailVerified()).isFalse();
        assertThat(savedUser.isTermsAccepted()).isTrue();
        assertThat(savedUser.getVerificationCode()).hasSize(6);
        assertThat(savedUser.getVerificationCodeExpiresAt()).isAfter(Instant.now());

        verify(emailService).sendVerificationCode(eq("etudiant@univ-tlse3.fr"), eq(savedUser.getVerificationCode()));
    }

    @Test
    void register_EmailAlreadyUsed_ThrowsException() {
        when(userRepository.existsByEmail("etudiant@univ-tlse3.fr")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(validRegisterRequest))
                .isInstanceOf(EmailAlreadyUsedException.class)
                .hasMessage("Cet email est déjà utilisé");

        verify(userRepository, never()).save(any());
        verify(emailService, never()).sendVerificationCode(any(), any());
    }

    @Test
    void verifyEmail_Success() {
        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(AppUser.class))).thenAnswer(invocation -> invocation.getArgument(0));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("123456")
                .build();

        MessageResponse response = authService.verifyEmail(request);

        assertThat(response).isNotNull();
        assertThat(response.getMessage()).contains("validée avec succès");
        assertThat(sampleUser.isEmailVerified()).isTrue();
        assertThat(sampleUser.getVerificationCode()).isNull();
        assertThat(sampleUser.getVerificationCodeExpiresAt()).isNull();

        verify(userRepository).save(sampleUser);
    }

    @Test
    void verifyEmail_InvalidCode_ThrowsException() {
        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("999999")
                .build();

        assertThatThrownBy(() -> authService.verifyEmail(request))
                .isInstanceOf(InvalidVerificationCodeException.class)
                .hasMessage("Code de vérification invalide ou expiré");

        verify(userRepository, never()).save(any());
    }

    @Test
    void verifyEmail_ExpiredCode_ThrowsException() {
        sampleUser.setVerificationCodeExpiresAt(Instant.now().minus(Duration.ofMinutes(1)));
        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("123456")
                .build();

        assertThatThrownBy(() -> authService.verifyEmail(request))
                .isInstanceOf(InvalidVerificationCodeException.class)
                .hasMessage("Code de vérification invalide ou expiré");
    }

    @Test
    void login_Success() {
        sampleUser.setEmailVerified(true);
        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("MotDePasse123!", "hashed_password")).thenReturn(true);

        LoginRequest request = LoginRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("MotDePasse123!")
                .build();

        AuthResponse response = authService.login(request);

        assertThat(response).isNotNull();
        assertThat(response.getUserId()).isEqualTo(1L);
        assertThat(response.getEmail()).isEqualTo("etudiant@univ-tlse3.fr");
        assertThat(response.isEmailVerified()).isTrue();
        assertThat(response.getMessage()).isEqualTo("Connexion réussie");
    }

    @Test
    void login_EmailNotVerified_ThrowsException() {
        sampleUser.setEmailVerified(false);
        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("MotDePasse123!", "hashed_password")).thenReturn(true);

        LoginRequest request = LoginRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("MotDePasse123!")
                .build();

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(EmailNotVerifiedException.class)
                .hasMessage("Veuillez valider votre adresse email avant de vous connecter");
    }

    @Test
    void login_WrongPassword_ThrowsException() {
        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("MauvaisMotDePasse", "hashed_password")).thenReturn(false);

        LoginRequest request = LoginRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("MauvaisMotDePasse")
                .build();

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class)
                .hasMessage("Identifiants invalides");
    }
}
