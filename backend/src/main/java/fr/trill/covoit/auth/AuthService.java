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
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public MessageResponse register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(email)) {
            throw new EmailAlreadyUsedException("Cet email est déjà utilisé");
        }

        String verificationCode = generateSixDigitCode();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(15);

        User user = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .emailVerified(false)
                .termsAccepted(Boolean.TRUE.equals(request.getTermsAccepted()))
                .verificationCode(verificationCode)
                .verificationCodeExpiresAt(expiresAt)
                .role("USER")
                .build();

        userRepository.save(user);
        emailService.sendVerificationCode(email, verificationCode);

        return MessageResponse.builder()
                .message("Inscription réussie. Un code de validation vous a été envoyé par email.")
                .build();
    }

    @Transactional
    public MessageResponse verifyEmail(VerifyEmailRequest request) {
        String email = request.getEmail().trim().toLowerCase();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidVerificationCodeException("Code de validation invalide ou expiré"));

        if (user.getVerificationCode() == null ||
                !user.getVerificationCode().equals(request.getCode()) ||
                user.getVerificationCodeExpiresAt() == null ||
                user.getVerificationCodeExpiresAt().isBefore(LocalDateTime.now())) {
            throw new InvalidVerificationCodeException("Code de validation invalide ou expiré");
        }

        user.setEmailVerified(true);
        user.setVerificationCode(null);
        user.setVerificationCodeExpiresAt(null);
        userRepository.save(user);

        return MessageResponse.builder()
                .message("Adresse email validée avec succès. Vous pouvez maintenant vous connecter.")
                .build();
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("Identifiants invalides"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new InvalidCredentialsException("Identifiants invalides");
        }

        if (!user.isEmailVerified()) {
            throw new EmailNotVerifiedException("Veuillez valider votre adresse email avant de vous connecter");
        }

        return AuthResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .role(user.getRole())
                .emailVerified(user.isEmailVerified())
                .message("Connexion réussie")
                .build();
    }

    private String generateSixDigitCode() {
        int code = secureRandom.nextInt(1_000_000);
        return String.format("%06d", code);
    }
}
