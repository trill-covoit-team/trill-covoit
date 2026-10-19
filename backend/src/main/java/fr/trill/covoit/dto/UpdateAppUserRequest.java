package fr.trill.covoit.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateAppUserRequest {
    private String email;
    private String passwordHash;
    private Boolean emailVerified;
    private String firstName;
    private String lastName;
    private String photoUrl;
    private String bio;
}