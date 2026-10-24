package fr.trill.covoit.service;

import fr.trill.covoit.dto.*;
import fr.trill.covoit.exception.*;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.model.AuthSession;
import fr.trill.covoit.model.RefreshToken;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.repository.AuthSessionRepository;
import fr.trill.covoit.repository.RefreshTokenRepository;
import fr.trill.covoit.security.AppUserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final int CODE_EXPIRATION_MINUTES = 15;
    private final AuthenticationManager authenticationManager;
    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final SecureRandom secureRandom = new SecureRandom();
    private final AccessTokenService accessTokenService;
    private final Clock clock;
    private final AuthSessionRepository authSessionRepository;
    private final RefreshTokenService refreshTokenService;
    private final RefreshTokenRepository refreshTokenRepository;

    @Value("${app.auth.refresh-token-ttl}")
    private Duration refreshTokenTtl;

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

    @Transactional
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

        String accessToken = accessTokenService.createAccessToken(principal.getUserId());

        Instant now = clock.instant();

        AuthSession session = AuthSession.builder()
                .userId(principal.getUserId())
                .expiresAt(now.plus(refreshTokenTtl))
                .build();

        AuthSession savedSession = authSessionRepository.save(session);

        String refreshToken = refreshTokenService.createRefreshToken(savedSession.getSessionId());

        return AuthResponse.builder()
                .userId(principal.getUserId())
                .email(principal.getEmail())
                .emailVerified(principal.isEmailVerified())
                .accessToken(accessToken)
                .tokenType("Bearer")
                .refreshToken(refreshToken)
                .message("Connexion réussie.")
                .build();
    }

    @Transactional(noRollbackFor = RefreshTokenReuseException.class)
    public RefreshTokenResponse refreshToken(RefreshTokenRequest request) {
        // Identifier la session sans charger le token.
        String tokenHash = refreshTokenService.hashRefreshToken(request.getRefreshToken());

        Long sessionId = refreshTokenRepository
                .findSessionIdByTokenHash(tokenHash)
                .orElseThrow(InvalidRefreshTokenException::new);

        // Obtenir le verrou sur la session.
        AuthSession session = authSessionRepository
                .findBySessionId(sessionId)
                .orElseThrow(InvalidRefreshTokenException::new);

        // Lire le token après l'obtention du verrou.
        RefreshToken token = refreshTokenRepository
                .findByTokenHash(tokenHash)
                .orElseThrow(InvalidRefreshTokenException::new);

        Instant now = clock.instant();

        // Vérifier que la session est encore utilisable.
        if (session.getRevokedAt() != null || !session.getExpiresAt().isAfter(now)) {
            throw new InvalidRefreshTokenException();
        }

        // Reconnaître une réutilisation et révoquer cette session.
        if (token.getUsedAt() != null) {
            session.setRevokedAt(now);
            authSessionRepository.save(session);

            throw new RefreshTokenReuseException();
        }

        // Vérifier que le compte existe et reste vérifié.
        AppUser user = userRepository
                .findById(session.getUserId())
                .orElseThrow(InvalidRefreshTokenException::new);

        // Consommer l'ancien token et prolonger la session.
        token.setUsedAt(now);
        refreshTokenRepository.save(token);

        session.setExpiresAt(now.plus(refreshTokenTtl));
        authSessionRepository.save(session);

        // Créer les nouveaux tokens.
        String newAccessToken = accessTokenService
                .createAccessToken(user.getUserId());

        String newRefreshToken = refreshTokenService
                .createRefreshToken(session.getSessionId());

        return RefreshTokenResponse.builder()
                .accessToken(newAccessToken)
                .tokenType("Bearer")
                .refreshToken(newRefreshToken)
                .build();
    }

    @Transactional
    public void logout(RefreshTokenRequest request) {
        String tokenHash = refreshTokenService.hashRefreshToken(request.getRefreshToken());

        Optional<Long> sessionId = refreshTokenRepository
                .findSessionIdByTokenHash(tokenHash);
        if (sessionId.isEmpty()) return;

        Optional<AuthSession> optionalSession = authSessionRepository
                .findBySessionId(sessionId.get());
        if (optionalSession.isEmpty()) return;

        AuthSession session = optionalSession.get();
        if (session.getRevokedAt() != null) return;

        session.setRevokedAt(clock.instant());
        authSessionRepository.save(session);
    }

    private String generateVerificationCode() {
        int code = secureRandom.nextInt(1_000_000);
        return String.format("%06d", code);
    }
}
