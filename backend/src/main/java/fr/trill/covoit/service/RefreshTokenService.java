package fr.trill.covoit.service;

import fr.trill.covoit.model.RefreshToken;
import fr.trill.covoit.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    public static final String HASH_ALGORITHM = "SHA-256";
    private final SecureRandom secureRandom = new SecureRandom();
    private final RefreshTokenRepository refreshTokenRepository;

    private String generateRefreshToken() {
        byte[] randomBytes = new byte[32];
        secureRandom.nextBytes(randomBytes);

        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(randomBytes);
    }

    public String hashRefreshToken(String refreshToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance(HASH_ALGORITHM);

            byte[] hash = digest.digest(refreshToken.getBytes(StandardCharsets.UTF_8));

            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(HASH_ALGORITHM + " n'est pas disponible");
        }
    }

    public String createRefreshToken(Long sessionId) {
        String refreshToken = this.generateRefreshToken();
        String refreshTokenHash = this.hashRefreshToken(refreshToken);

        RefreshToken token = RefreshToken.builder()
                .tokenHash(refreshTokenHash)
                .sessionId(sessionId)
                .build();

        refreshTokenRepository.save(token);

        return refreshToken;
    }
}
