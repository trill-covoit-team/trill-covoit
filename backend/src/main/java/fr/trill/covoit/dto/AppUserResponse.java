package fr.trill.covoit.dto;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;

@Getter
@Builder
@JsonPropertyOrder({"userId", "email", "passwordHash", "emailVerified", "firstName", "lastName", "photoUrl", "bio", "termsAccepted", "verificationCode", "verificationCodeExpiresAt", "createdAt", "updatedAt"})
public class AppUserResponse {
    private Long userId;
    private String email;
    private String passwordHash;
    private boolean emailVerified;
    private String firstName;
    private String lastName;
    private String photoUrl;
    private String bio;
    private boolean termsAccepted;
    private String verificationCode;
    private Instant verificationCodeExpiresAt;
    private Instant createdAt;
    private Instant updatedAt;
}