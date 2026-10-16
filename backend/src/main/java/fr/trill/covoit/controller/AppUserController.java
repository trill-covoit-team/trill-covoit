package fr.trill.covoit.controller;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.upload.PhotoUploader;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Optional;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class AppUserController {
    private final AppUserRepository appUserRepository;
    private final PhotoUploader photoUploader;

    @GetMapping("/{id}")
    public Optional<AppUser> getOneUser(@PathVariable int id) {
        return appUserRepository.findById(id);
    }

    @PatchMapping("/{id}")
    public @ResponseBody String patchOneUser(@PathVariable int id,
                                             @RequestParam(required = false) String email,
                                             @RequestParam(required = false) String passwordHash,
                                             @RequestParam(required = false) Boolean emailVerified,
                                             @RequestParam(required = false) String firstName,
                                             @RequestParam(required = false) String lastName,
                                             @RequestParam(required = false) String photoUrl,
                                             @RequestParam(required = false) String bio) {
        Optional<AppUser> user = appUserRepository.findById(id);
        if (user.isEmpty()) {
            return "404 not found";
        }
        AppUser n = user.get();
        if (email != null) n.setEmail(email);
        if (passwordHash != null) n.setPasswordHash(passwordHash);
        if (emailVerified != null) n.setEmailVerified(emailVerified);
        if (firstName != null) n.setFirstName(firstName);
        if (lastName != null) n.setLastName(lastName);
        if (photoUrl != null) n.setPhotoUrl(photoUrl);
        if (bio != null) n.setBio(bio);
        appUserRepository.save(n);
        return "Saved";
    }

    @PutMapping("/{id}/photo")
    public ResponseEntity<String> putOneUserPhoto(
            @PathVariable int id,
            @RequestParam("file") MultipartFile file) {

        Optional<AppUser> userOpt = appUserRepository.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404).body("Utilisateur non trouvé");
        }

        try {
            String response = photoUploader.savePhoto(file, id, userOpt.get());
            if (!response.equals("Saved")) {
                return ResponseEntity.badRequest().body(response);
            }
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            return ResponseEntity.status(500).body("Erreur serveur lors de la sauvegarde");
        }
    }

    @DeleteMapping("/{id}/photo")
    public ResponseEntity<String> deleteOneUserPhoto(@PathVariable int id) {
        Optional<AppUser> userOpt = appUserRepository.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404).body("Utilisateur non trouvé");
        }

        boolean success = photoUploader.deletePhoto(id, userOpt.get());
        if (success) {
            return ResponseEntity.ok("Successfully deleted photo");
        } else {
            return ResponseEntity.status(404).body("Photo not found for this user");
        }
    }
}
