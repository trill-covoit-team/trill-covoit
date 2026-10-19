package fr.trill.covoit.service;

import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.upload.PhotoUploader;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;

@Service
@RequiredArgsConstructor
public class AppUserService {

    private final AppUserRepository appUserRepository;
    private final PhotoUploader photoUploader;

    @Transactional(readOnly = true)
    public AppUser getOneUser(Long userId) {
        return appUserRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Utilisateur non trouvé"));
    }

    @Transactional
    public MessageResponse patchOneUser(Long userId, UpdateAppUserRequest request) {
        AppUser user = getOneUser(userId);

        if (request.getEmail() != null) user.setEmail(request.getEmail());
        if (request.getPasswordHash() != null) user.setPasswordHash(request.getPasswordHash());
        if (request.getEmailVerified() != null) user.setEmailVerified(request.getEmailVerified());
        if (request.getFirstName() != null) user.setFirstName(request.getFirstName());
        if (request.getLastName() != null) user.setLastName(request.getLastName());
        if (request.getPhotoUrl() != null) user.setPhotoUrl(request.getPhotoUrl());
        if (request.getBio() != null) user.setBio(request.getBio());

        appUserRepository.save(user);
        return new MessageResponse("Profil mis à jour avec succès");
    }

    @Transactional
    public MessageResponse saveUserPhoto(Long userId, MultipartFile file) throws IOException {
        AppUser user = getOneUser(userId);

        String response = photoUploader.savePhoto(file, userId, user);
        if (!response.equals("Saved")) {
            throw new IllegalArgumentException(response);
        }
        return new MessageResponse("Photo enregistrée avec succès");
    }

    @Transactional
    public MessageResponse deleteUserPhoto(Long userId) {
        AppUser user = getOneUser(userId);

        boolean success = photoUploader.deletePhoto(userId, user);
        if (!success) {
            throw new RuntimeException("Photo non trouvée pour cet utilisateur");
        }
        return new MessageResponse("Photo supprimée avec succès");
    }
}