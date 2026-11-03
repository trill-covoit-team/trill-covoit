package fr.trill.covoit.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class RefreshTokenResponse {

    private String accessToken;
    private String tokenType;
    private String refreshToken;
}
