package fr.trill.covoit.controller;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class AppUserController {
    private final AppUserRepository appUserRepository;
    private static final long MAX_FILE_SIZE = 5242880;

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
        return "saved";
    }

    @PutMapping("/{id}/photo")
    public ResponseEntity<String> putOneUserPhoto(
            @PathVariable int id,
            @RequestParam("file") MultipartFile file) {

        // Vérification utilisateur existe
        Optional<AppUser> userOpt = appUserRepository.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404).body("404 not found");
        }
        // Vérifications photo
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("Fichier vide.");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            return ResponseEntity.badRequest().body("La taille du fichier dépasse la limite autorisée de 5 Mio.");
        }
        String contentType = file.getContentType();
        if (contentType == null || !(contentType.equals("image/jpeg") || contentType.equals("image/png"))) {
            return ResponseEntity.badRequest().body("Le fichier fourni n'est pas une image valide (formats acceptés : JPEG, PNG).");
        }
        // sauvegarde
        String fakePhotoUrl = "/AppUserPhotos/" + file.getOriginalFilename();
        AppUser user = userOpt.get();
        user.setPhotoUrl(fakePhotoUrl);
        appUserRepository.save(user);

        return ResponseEntity.ok("saved");
    }

    @DeleteMapping("/{id}/photo")
    public @ResponseBody String deleteOneUserPhoto(@PathVariable int id) {
        Optional<AppUser> user = appUserRepository.findById(id);
        if (user.isEmpty()) {
            return "404 not found";
        }
        AppUser n = user.get();
        n.setPhotoUrl("");
        appUserRepository.save(n);
        return "Successfully deleted photo";
    }
}
