package fr.trill.covoit.auth;

import fr.trill.covoit.auth.dto.AuthResponse;
import fr.trill.covoit.auth.dto.LoginRequest;
import fr.trill.covoit.auth.dto.MessageResponse;
import fr.trill.covoit.auth.dto.RegisterRequest;
import fr.trill.covoit.auth.dto.VerifyEmailRequest;
import fr.trill.covoit.auth.exception.EmailAlreadyUsedException;
import fr.trill.covoit.auth.exception.EmailNotVerifiedException;
import fr.trill.covoit.auth.exception.InvalidCredentialsException;
import fr.trill.covoit.auth.exception.InvalidVerificationCodeException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private AuthService authService;

    private RegisterRequest registerRequest;

    @BeforeEach
    void setUp() {
        registerRequest = RegisterRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("motdepasse123")
                .termsAccepted(true)
                .build();
    }

    @Test
    void register_ShouldCreateUnverifiedUserAndSendCode_WhenDataIsValid() {
        when(userRepository.existsByEmail("etudiant@univ-tlse3.fr")).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed_password");

        MessageResponse response = authService.register(registerRequest);

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        User savedUser = userCaptor.getValue();

        assertThat(savedUser.getEmail()).isEqualTo("etudiant@univ-tlse3.fr");
        assertThat(savedUser.isEmailVerified()).isFalse();
        assertThat(savedUser.getVerificationCode()).isNotNull().hasSize(6);
        assertThat(savedUser.getVerificationCodeExpiresAt()).isAfter(LocalDateTime.now());
        verify(emailService).sendVerificationCode(eq("etudiant@univ-tlse3.fr"), eq(savedUser.getVerificationCode()));
        assertThat(response.getMessage()).contains("Inscription réussie");
    }

    @Test
    void register_ShouldThrowException_WhenEmailAlreadyExists() {
        when(userRepository.existsByEmail("etudiant@univ-tlse3.fr")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(registerRequest))
                .isInstanceOf(EmailAlreadyUsedException.class)
                .hasMessage("Cet email est déjà utilisé");

        verify(userRepository, never()).save(any());
        verify(emailService, never()).sendVerificationCode(anyString(), anyString());
    }

    @Test
    void verifyEmail_ShouldActivateAccount_WhenCodeIsValid() {
        User user = User.builder()
                .email("etudiant@univ-tlse3.fr")
                .emailVerified(false)
                .verificationCode("123456")
                .verificationCodeExpiresAt(LocalDateTime.now().plusMinutes(10))
                .build();

        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(user));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("123456")
                .build();

        MessageResponse response = authService.verifyEmail(request);

        assertThat(user.isEmailVerified()).isTrue();
        assertThat(user.getVerificationCode()).isNull();
        assertThat(user.getVerificationCodeExpiresAt()).isNull();
        verify(userRepository).save(user);
        assertThat(response.getMessage()).contains("validée avec succès");
    }

    @Test
    void verifyEmail_ShouldThrowException_WhenCodeIsIncorrect() {
        User user = User.builder()
                .email("etudiant@univ-tlse3.fr")
                .emailVerified(false)
                .verificationCode("123456")
                .verificationCodeExpiresAt(LocalDateTime.now().plusMinutes(10))
                .build();

        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(user));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("999999")
                .build();

        assertThatThrownBy(() -> authService.verifyEmail(request))
                .isInstanceOf(InvalidVerificationCodeException.class)
                .hasMessage("Code de validation invalide ou expiré");

        assertThat(user.isEmailVerified()).isFalse();
    }

    @Test
    void verifyEmail_ShouldThrowException_WhenCodeIsExpired() {
        User user = User.builder()
                .email("etudiant@univ-tlse3.fr")
                .emailVerified(false)
                .verificationCode("123456")
                .verificationCodeExpiresAt(LocalDateTime.now().minusMinutes(1))
                .build();

        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(user));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("123456")
                .build();

        assertThatThrownBy(() -> authService.verifyEmail(request))
                .isInstanceOf(InvalidVerificationCodeException.class)
                .hasMessage("Code de validation invalide ou expiré");
    }

    @Test
    void login_ShouldReturnAuthResponse_WhenCredentialsAreValidAndEmailVerified() {
        User user = User.builder()
                .id(1L)
                .email("etudiant@univ-tlse3.fr")
                .passwordHash("hashed_password")
                .emailVerified(true)
                .role("USER")
                .build();

        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("motdepasse123", "hashed_password")).thenReturn(true);

        LoginRequest loginRequest = LoginRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("motdepasse123")
                .build();

        AuthResponse response = authService.login(loginRequest);

        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getEmail()).isEqualTo("etudiant@univ-tlse3.fr");
        assertThat(response.isEmailVerified()).isTrue();
        assertThat(response.getMessage()).isEqualTo("Connexion réussie");
    }

    @Test
    void login_ShouldThrowException_WhenPasswordIsIncorrect() {
        User user = User.builder()
                .email("etudiant@univ-tlse3.fr")
                .passwordHash("hashed_password")
                .emailVerified(true)
                .build();

        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("mauvaismdp", "hashed_password")).thenReturn(false);

        LoginRequest loginRequest = LoginRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("mauvaismdp")
                .build();

        assertThatThrownBy(() -> authService.login(loginRequest))
                .isInstanceOf(InvalidCredentialsException.class)
                .hasMessage("Identifiants invalides");
    }

    @Test
    void login_ShouldThrowException_WhenEmailIsNotVerified() {
        User user = User.builder()
                .email("etudiant@univ-tlse3.fr")
                .passwordHash("hashed_password")
                .emailVerified(false)
                .build();

        when(userRepository.findByEmail("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("motdepasse123", "hashed_password")).thenReturn(true);

        LoginRequest loginRequest = LoginRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .password("motdepasse123")
                .build();

        assertThatThrownBy(() -> authService.login(loginRequest))
                .isInstanceOf(EmailNotVerifiedException.class)
                .hasMessage("Veuillez valider votre adresse email avant de vous connecter");
    }
}
