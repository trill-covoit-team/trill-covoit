package fr.trill.covoit.service;

import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.RegisterRequest;
import fr.trill.covoit.dto.VerifyEmailRequest;
import fr.trill.covoit.exception.EmailAlreadyUsedException;
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
        when(userRepository.existsByEmailIgnoreCase(anyString())).thenReturn(false);
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
        when(userRepository.existsByEmailIgnoreCase("etudiant@univ-tlse3.fr")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(validRegisterRequest))
                .isInstanceOf(EmailAlreadyUsedException.class)
                .hasMessage("Cette adresse email est déjà utilisée.");

        verify(userRepository, never()).save(any());
        verify(emailService, never()).sendVerificationCode(any(), any());
    }

    @Test
    void verifyEmail_Success() {
        when(userRepository.findByEmailIgnoreCase("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(AppUser.class))).thenAnswer(invocation -> invocation.getArgument(0));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("123456")
                .build();

        MessageResponse response = authService.verifyEmail(request);

        assertThat(response).isNotNull();
        assertThat(response.getMessage()).contains("email a été validée");
        assertThat(sampleUser.isEmailVerified()).isTrue();
        assertThat(sampleUser.getVerificationCode()).isNull();
        assertThat(sampleUser.getVerificationCodeExpiresAt()).isNull();

        verify(userRepository).save(sampleUser);
    }

    @Test
    void verifyEmail_InvalidCode_ThrowsException() {
        when(userRepository.findByEmailIgnoreCase("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("999999")
                .build();

        assertThatThrownBy(() -> authService.verifyEmail(request))
                .isInstanceOf(InvalidVerificationCodeException.class)
                .hasMessage("Le code de validation est invalide ou expiré.");

        verify(userRepository, never()).save(any());
    }

    @Test
    void verifyEmail_ExpiredCode_ThrowsException() {
        sampleUser.setVerificationCodeExpiresAt(Instant.now().minus(Duration.ofMinutes(1)));
        when(userRepository.findByEmailIgnoreCase("etudiant@univ-tlse3.fr")).thenReturn(Optional.of(sampleUser));

        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .email("etudiant@univ-tlse3.fr")
                .code("123456")
                .build();

        assertThatThrownBy(() -> authService.verifyEmail(request))
                .isInstanceOf(InvalidVerificationCodeException.class)
                .hasMessage("Le code de validation est invalide ou expiré.");
    }
}
