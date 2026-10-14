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
    public Optional<AppUser> getOneUser(@RequestParam int id) {
        return appUserRepository.findById(id);
    }

    @PatchMapping("/{id}")
    public @ResponseBody String patchOneUser(@RequestParam int id, @RequestParam String email, @RequestParam String passwordHash, @RequestParam boolean emailVerified, @RequestParam String firstName, @RequestParam String lastName, @RequestParam String photoUrl, @RequestParam String bio) {
        AppUser n = new AppUser();
        n.setEmail(email);
        n.setPasswordHash(passwordHash);
        n.setEmailVerified(emailVerified);
        n.setFirstName(firstName);
        n.setLastName(lastName);
        n.setPhotoUrl(photoUrl);
        n.setBio(bio);
        appUserRepository.save(n);
        return "saved";
    }

    @PutMapping("/{id}/photo")
    public @ResponseBody String patchOneUser(@RequestParam int id, @RequestParam String photoUrl) {
        AppUser n = new AppUser();
        n.setPhotoUrl(photoUrl);
        appUserRepository.save(n);
        return "saved";
    }

    @DeleteMapping("/{id}/photo")
    public @ResponseBody String patchOneUser(@RequestParam int id) {
        AppUser n = new AppUser();
        n.setPhotoUrl("");
        appUserRepository.save(n);
        return "saved";
    }
}
