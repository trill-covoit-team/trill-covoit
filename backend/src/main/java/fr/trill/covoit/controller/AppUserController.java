package fr.trill.covoit.controller;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class AppUserController {
    private final AppUserRepository appUserRepository;

    @GetMapping
    public List<AppUser> getAllUsers() {
        return appUserRepository.findAll();
    }

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
    public @ResponseBody String patchOneUser(@PathVariable int id, @RequestParam String photoUrl) {
        Optional<AppUser> user = appUserRepository.findById(id);
        if (user.isEmpty()) {
            return "404 not found";
        }
        AppUser n = user.get();
        n.setPhotoUrl(photoUrl);
        appUserRepository.save(n);
        return "saved";
    }

    @DeleteMapping("/{id}/photo")
    public @ResponseBody String patchOneUser(@PathVariable int id) {
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
