package fr.trill.covoit.controller;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/appUser")
@RequiredArgsConstructor
public class AppUserController {
    private final AppUserRepository appUserRepository;

    @GetMapping
    public List<AppUser> getAllUsers() {
        return appUserRepository.findAll();
    }
}
