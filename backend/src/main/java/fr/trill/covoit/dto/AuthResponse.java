package fr.trill.covoit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private Long id;
    private Long userId;
    private String email;
    private String role;
    private boolean emailVerified;
    private String accessToken;
    private String tokenType;
    private String message;
}
