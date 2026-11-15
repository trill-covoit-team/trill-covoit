package fr.trill.covoit.dto;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;

@Getter
@Builder
@JsonPropertyOrder({"userId", "firstName", "lastName", "photoUrl", "bio", "createdAt"})
public class PublicUserResponse {

    private Long userId;
    private String firstName;
    private String lastName;
    private String photoUrl;
    private String bio;
    private Instant createdAt;
}
