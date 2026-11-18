package fr.trill.covoit.controller;

import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.MyProfileResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest;
import fr.trill.covoit.service.AppUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Objects;

@RestController
@RequestMapping("/users/me")
@RequiredArgsConstructor
public class AppUserController {

    private final AppUserService appUserService;

    @GetMapping
    public ResponseEntity<MyProfileResponse> getMyProfile(@AuthenticationPrincipal Jwt jwt) {
        Long userId = Long.valueOf(Objects.requireNonNull(jwt.getSubject()));
        MyProfileResponse response = appUserService.getMyProfile(userId);
        return ResponseEntity.ok(response);
    }

    @PatchMapping
    public ResponseEntity<MyProfileResponse> updateMyProfile(@AuthenticationPrincipal Jwt jwt,
                                                             @Valid @RequestBody UpdateAppUserRequest request) {
        Long userId = Long.valueOf(Objects.requireNonNull(jwt.getSubject()));
        MyProfileResponse response = appUserService.updateMyProfile(userId, request);
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