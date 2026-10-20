package fr.trill.covoit.service;

import fr.trill.covoit.dto.*;
import fr.trill.covoit.exception.EmailAlreadyUsedException;
import fr.trill.covoit.exception.EmailNotVerifiedException;
import fr.trill.covoit.exception.InvalidCredentialsException;
import fr.trill.covoit.exception.InvalidVerificationCodeException;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.security.AppUserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final int CODE_EXPIRATION_MINUTES = 15;
    private final AuthenticationManager authenticationManager;
    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public MessageResponse register(RegisterRequest request) {
        if (userRepository.existsByEmailIgnoreCase(request.getEmail())) {
            throw new EmailAlreadyUsedException();
        }

        String code = generateVerificationCode();
        Instant expiresAt = Instant.now().plus(Duration.ofMinutes(CODE_EXPIRATION_MINUTES));

        AppUser user = AppUser.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .termsAccepted(request.isTermsAccepted())
                .emailVerified(false)
                .verificationCode(code)
                .verificationCodeExpiresAt(expiresAt)
                .build();

        userRepository.save(user);
        emailService.sendVerificationCode(user.getEmail(), code);

        return new MessageResponse("Votre compte a été créé. Un code de validation vous a été envoyé par email.");
    }

    @Transactional
    public MessageResponse verifyEmail(VerifyEmailRequest request) {
        AppUser user = userRepository.findByEmailIgnoreCase(request.getEmail())
                .orElseThrow(InvalidVerificationCodeException::new);

        if (user.getVerificationCode() == null
                || !user.getVerificationCode().equals(request.getCode())
                || user.getVerificationCodeExpiresAt() == null
                || user.getVerificationCodeExpiresAt().isBefore(Instant.now())) {
            throw new InvalidVerificationCodeException();
        }

        user.setEmailVerified(true);
        user.setVerificationCode(null);
        user.setVerificationCodeExpiresAt(null);
        userRepository.save(user);

        return new MessageResponse("Votre adresse email a été validée. Vous pouvez maintenant vous connecter.");
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        Authentication result;

        try {
            result = authenticationManager.authenticate(
                    UsernamePasswordAuthenticationToken.unauthenticated(
                            request.getEmail(),
                            request.getPassword()
                    )
            );
        } catch (BadCredentialsException exception) {
            throw new InvalidCredentialsException();
        }

        if (!(result.getPrincipal() instanceof AppUserPrincipal principal)) {
            throw new IllegalStateException(
                    "Identité authentifiée absente ou d'un type inattendu."
            );
        }

        if (!principal.isEmailVerified()) {
            throw new EmailNotVerifiedException();
        }

        return AuthResponse.builder()
                .userId(principal.getUserId())
                .email(principal.getEmail())
                .emailVerified(principal.isEmailVerified())
                .message("Connexion réussie.")
                .build();
    }

    private String generateVerificationCode() {
        int code = secureRandom.nextInt(1_000_000);
        return String.format("%06d", code);
    }
}
