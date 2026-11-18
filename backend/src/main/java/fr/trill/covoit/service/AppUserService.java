package fr.trill.covoit.service;

import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.MyProfileResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest;
import fr.trill.covoit.exception.AuthenticatedUserNotFoundException;
import fr.trill.covoit.exception.EmptyUpdateException;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.upload.PhotoUploader;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Service
@RequiredArgsConstructor
public class AppUserService {

    private final AppUserRepository appUserRepository;
    private final PhotoUploader photoUploader;

    private MyProfileResponse toMyProfileResponse(AppUser user) {
        return MyProfileResponse.builder()
                .userId(user.getUserId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .photoUrl(user.getPhotoUrl())
                .bio(user.getBio())
                .createdAt(user.getCreatedAt())
                .build();
    }

    @Transactional(readOnly = true)
    public MyProfileResponse getMyProfile(Long userId) {
        AppUser user = getAuthenticatedUser(userId);
        return toMyProfileResponse(user);
    }

    @Transactional
    public MyProfileResponse updateMyProfile(Long userId, UpdateAppUserRequest request) {
        if (request.getFirstName() == null && request.getLastName() == null && request.getBio() == null) {
            throw new EmptyUpdateException();
        }

        AppUser user = getAuthenticatedUser(userId);

        // Un champ absent reste inchangé ; une chaîne vide efface le nom ou la bio.
        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName().isEmpty() ? null : request.getLastName());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio().isEmpty() ? null : request.getBio());
        }

        AppUser savedUser = appUserRepository.save(user);

        return toMyProfileResponse(savedUser);
    }

    @Transactional
    public MessageResponse saveUserPhoto(Long userId, MultipartFile file) throws IOException {
        AppUser user = getAuthenticatedUser(userId);

        String response = photoUploader.savePhoto(file, userId, user);
        if (!response.equals("Saved")) {
            throw new IllegalArgumentException(response);
        }
        return new MessageResponse("Photo enregistrée avec succès");
    }

    @Transactional
    public MessageResponse deleteUserPhoto(Long userId) {
        AppUser user = getAuthenticatedUser(userId);

        boolean success = photoUploader.deletePhoto(userId, user);
        if (!success) {
            throw new RuntimeException("Photo non trouvée pour cet utilisateur");
        }
        return new MessageResponse("Photo supprimée avec succès");
    }

    private AppUser getAuthenticatedUser(Long userId) {
        return appUserRepository.findById(userId)
                .orElseThrow(AuthenticatedUserNotFoundException::new);
    }
}