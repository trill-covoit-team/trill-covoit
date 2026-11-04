package fr.trill.covoit.controller;

import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.service.AppUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/users/me")
@RequiredArgsConstructor
public class AppUserController {

    private final AppUserService appUserService;

    @GetMapping
    public ResponseEntity<AppUser> getOneUser(@AuthenticationPrincipal Jwt jwt) {
        Long userId = Long.valueOf(jwt.getSubject());
        AppUser user = appUserService.getOneUser(userId);
        return ResponseEntity.ok(user);
    }

    @PatchMapping
    public ResponseEntity<MessageResponse> patchOneUser(@AuthenticationPrincipal Jwt jwt, @RequestBody UpdateAppUserRequest request) {
        Long userId = Long.valueOf(jwt.getSubject());
        MessageResponse response = appUserService.patchOneUser(userId, request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/photo")
    public ResponseEntity<MessageResponse> putOneUserPhoto(@AuthenticationPrincipal Jwt jwt, @RequestParam("file") MultipartFile file) {
        Long userId = Long.valueOf(jwt.getSubject());
        try {
            MessageResponse response = appUserService.saveUserPhoto(userId, file);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Erreur serveur lors de la sauvegarde"));
        }
    }

    @DeleteMapping("/photo")
    public ResponseEntity<MessageResponse> deleteOneUserPhoto(@AuthenticationPrincipal Jwt jwt) {
        Long userId = Long.valueOf(jwt.getSubject());
        try {
            MessageResponse response = appUserService.deleteUserPhoto(userId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new MessageResponse(e.getMessage()));
        }
    }
}