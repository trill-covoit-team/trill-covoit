package fr.trill.covoit.controller;

import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.service.AppUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class AppUserController {

    private final AppUserService appUserService;

    @GetMapping("/{userId}")
    public ResponseEntity<AppUser> getOneUser(@PathVariable Long userId) {
        AppUser user = appUserService.getOneUser(userId);
        return ResponseEntity.ok(user);
    }

    @PatchMapping("/{userId}")
    public ResponseEntity<MessageResponse> patchOneUser(@PathVariable Long userId, @RequestBody UpdateAppUserRequest request) {
        MessageResponse response = appUserService.patchOneUser(userId, request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{userId}/photo")
    public ResponseEntity<MessageResponse> putOneUserPhoto(@PathVariable Long userId, @RequestParam("file") MultipartFile file) {
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

    @DeleteMapping("/{userId}/photo")
    public ResponseEntity<MessageResponse> deleteOneUserPhoto(@PathVariable Long userId) {
        try {
            MessageResponse response = appUserService.deleteUserPhoto(userId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new MessageResponse(e.getMessage()));
        }
    }
}