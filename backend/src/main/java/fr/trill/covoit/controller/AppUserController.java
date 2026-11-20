package fr.trill.covoit.controller;

import fr.trill.covoit.dto.MyProfileResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest;
import fr.trill.covoit.service.AppUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

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

    @PutMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<MyProfileResponse> updatePhoto(@AuthenticationPrincipal Jwt jwt,
                                                         @RequestParam("file") MultipartFile file) {
        Long userId = Long.valueOf(Objects.requireNonNull(jwt.getSubject()));
        MyProfileResponse response = appUserService.updatePhoto(userId, file);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/photo")
    public ResponseEntity<Void> deletePhoto(@AuthenticationPrincipal Jwt jwt) {
        Long userId = Long.valueOf(Objects.requireNonNull(jwt.getSubject()));
        appUserService.deletePhoto(userId);
        return ResponseEntity.noContent().build();
    }
}