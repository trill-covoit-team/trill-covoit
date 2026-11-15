package fr.trill.covoit.service;

import fr.trill.covoit.dto.PublicUserResponse;
import fr.trill.covoit.model.AppUser;
import org.springframework.stereotype.Service;

@Service
public class AppUserService {

    public static PublicUserResponse toPublicResponse(AppUser user) {
        return PublicUserResponse.builder()
                .userId(user.getUserId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .photoUrl(user.getPhotoUrl())
                .bio(user.getBio())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
