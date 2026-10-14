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
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    private static final int CODE_EXPIRATION_MINUTES = 15;
    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public MessageResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyUsedException("Cet email est déjà utilisé");
        }

        String code = generateVerificationCode();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(CODE_EXPIRATION_MINUTES);

        AppUser user = AppUser.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .termsAccepted(request.isTermsAccepted())
                .emailVerified(false)
                .verificationCode(code)
                .verificationCodeExpiresAt(expiresAt)
                .role("USER")
                .build();

        userRepository.save(user);
        emailService.sendVerificationCode(user.getEmail(), code);

        return new MessageResponse("Votre compte a été créé. Un code de validation vous a été envoyé par email.");
    }

    @Transactional
    public MessageResponse verifyEmail(VerifyEmailRequest request) {
        AppUser user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new InvalidVerificationCodeException("Code de vérification invalide ou expiré"));

        if (user.getVerificationCode() == null
                || !user.getVerificationCode().equals(request.getCode())
                || user.getVerificationCodeExpiresAt() == null
                || user.getVerificationCodeExpiresAt().isBefore(LocalDateTime.now())) {
            throw new InvalidVerificationCodeException("Code de vérification invalide ou expiré");
        }

        user.setEmailVerified(true);
        user.setVerificationCode(null);
        user.setVerificationCodeExpiresAt(null);
        userRepository.save(user);

        return new MessageResponse("Votre adresse email a été validée avec succès. Vous pouvez maintenant vous connecter.");
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        AppUser user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new InvalidCredentialsException("Identifiants invalides"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new InvalidCredentialsException("Identifiants invalides");
        }

        if (!user.isEmailVerified()) {
            throw new EmailNotVerifiedException("Veuillez valider votre adresse email avant de vous connecter");
        }

        return AuthResponse.builder()
                .id(user.getId())
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getRole())
                .emailVerified(user.isEmailVerified())
                .accessToken("mock-session-" + user.getId())
                .tokenType("Bearer")
                .message("Connexion réussie")
                .build();
    }

    private String generateVerificationCode() {
        int code = secureRandom.nextInt(1_000_000);
        return String.format("%06d", code);
    }
}
