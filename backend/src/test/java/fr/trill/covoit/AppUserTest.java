package fr.trill.covoit;

import fr.trill.covoit.controller.AppUserController;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AppUserTest {

    @Mock
    private AppUserRepository appUserRepository;

    @InjectMocks
    private AppUserController appUserController;

    private AppUser user;

    @BeforeEach
    void setUp() {
        user = new AppUser();
        user.setFirstName("Marc");
        user.setLastName("Dutrain");
        user.setEmail("marc.dutrain@somemail.com");
        user.setEmailVerified(true);
        user.setPasswordHash("c6uz78j6jd786iz4dijzf5hi3zhf");
        user.setPhotoUrl("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSSZFl299Ls3IxqJVb_4HxEbfeT5tY2DXpAx9A2yX5t8w&s=10");
        user.setBio("employé d'une petite société");
    }

    @Test
    void testGetOneUserFound() {
        when(appUserRepository.findById(1)).thenReturn(Optional.of(user));

        Optional<AppUser> result = appUserController.getOneUser(1);

        assertTrue(result.isPresent());
        assertEquals("Marc", result.get().getFirstName());
    }

    @Test
    void testGetOneUserNotFound() {
        when(appUserRepository.findById(4)).thenReturn(Optional.empty());

        // When
        Optional<AppUser> result = appUserController.getOneUser(4);

        // Then
        assertTrue(result.isEmpty());
    }

    @Test
    void testPatchOneUser() {
        when(appUserRepository.findById(1)).thenReturn(Optional.of(user));
        when(appUserRepository.save(any(AppUser.class))).thenReturn(user);

        String response = appUserController.patchOneUser(
                1,
                null,                 // email
                null,                       // passwordHash
                null,                       // emailVerified
                "ryad",                     // nouveau prénom
                null,                       // lastName
                null,                       // photoUrl
                "Attention changement bio"  // nouvelle bio
        );
        assertEquals("saved", response);
        assertEquals("ryad", user.getFirstName());
        assertEquals("Attention changement bio", user.getBio());
        assertEquals("Dutrain", user.getLastName());

        verify(appUserRepository, times(1)).save(user);
    }

    @Test
    void testUploadPhotoSuccess() {
        // Given
        when(appUserRepository.findById(1)).thenReturn(Optional.of(user));
        when(appUserRepository.save(any(AppUser.class))).thenReturn(user);

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "avatar.png",
                "image/png",
                "contenu-image".getBytes()
        );

        ResponseEntity<String> response = appUserController.putOneUserPhoto(1, file);

        assertEquals(200, response.getStatusCode().value());
        assertEquals("saved", response.getBody());
        assertEquals("/AppUserPhotos/avatar.png", user.getPhotoUrl());

        verify(appUserRepository, times(1)).save(user);
    }

    @Test
    void testUploadPhotoInvalidType() {
        // Given
        when(appUserRepository.findById(1)).thenReturn(Optional.of(user));

        // Fichier avec un mauvais type MIME (ex: texte)
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "document.txt",
                "text/plain",
                "texte simple".getBytes()
        );

        ResponseEntity<String> response = appUserController.putOneUserPhoto(1, file);

        assertEquals(400, response.getStatusCode().value());
        assertTrue(response.getBody().contains("pas une image valide"));

        verify(appUserRepository, never()).save(any(AppUser.class));
    }

    @Test
    void testDeletePhotoSuccess() {
        user.setPhotoUrl("/AppUserPhotos/avatar.png");
        when(appUserRepository.findById(1)).thenReturn(Optional.of(user));
        when(appUserRepository.save(any(AppUser.class))).thenReturn(user);

        String response = appUserController.deleteOneUserPhoto(1);

        assertEquals("Successfully deleted photo", response);
        assertEquals("", user.getPhotoUrl());

        verify(appUserRepository, times(1)).save(user);
    }
}