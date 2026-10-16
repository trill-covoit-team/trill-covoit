package fr.trill.covoit.controller;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.upload.PhotoUploader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AppUserTest {

    @Mock
    private AppUserRepository appUserRepository;

    @InjectMocks
    private AppUserController appUserController;

    @Mock
    private PhotoUploader photoUploader;

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
        when(appUserRepository.findById(1L)).thenReturn(Optional.of(user));

        Optional<AppUser> result = appUserController.getOneUser(1L);

        assertTrue(result.isPresent());
        assertEquals("Marc", result.get().getFirstName());
    }

    @Test
    void testGetOneUserNotFound() {
        when(appUserRepository.findById(4L)).thenReturn(Optional.empty());

        // When
        Optional<AppUser> result = appUserController.getOneUser(4L);

        // Then
        assertTrue(result.isEmpty());
    }

    @Test
    void testPatchOneUser() {
        when(appUserRepository.findById(1L)).thenReturn(Optional.of(user));
        when(appUserRepository.save(any(AppUser.class))).thenReturn(user);

        String response = appUserController.patchOneUser(
                1L,
                null,                 // email
                null,                       // passwordHash
                null,                       // emailVerified
                "ryad",                     // nouveau prénom
                null,                       // lastName
                null,                       // photoUrl
                "Attention changement bio"  // nouvelle bio
        );
        assertEquals("Saved", response);
        assertEquals("ryad", user.getFirstName());
        assertEquals("Attention changement bio", user.getBio());
        assertEquals("Dutrain", user.getLastName());

        verify(appUserRepository, times(1)).save(user);
    }

    @Test
    void testUploadPhotoSuccess() throws IOException {
        when(appUserRepository.findById(1L)).thenReturn(Optional.of(user));
        when(photoUploader.savePhoto(any(), eq(1L), any(AppUser.class))).thenReturn("Saved");

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "avatar.png",
                "image/png",
                "contenu-image".getBytes()
        );

        ResponseEntity<String> response = appUserController.putOneUserPhoto(1L, file);

        assertEquals(200, response.getStatusCode().value());
        assertEquals("Saved", response.getBody());

        verify(photoUploader, times(1)).savePhoto(any(), eq(1L), any(AppUser.class));
    }

    @Test
    void testUploadPhotoInvalidType() throws IOException {
        // Given
        when(appUserRepository.findById(1L)).thenReturn(Optional.of(user));
        when(photoUploader.savePhoto(any(), eq(1L), any(AppUser.class))).thenReturn("Le fichier fourni n'est pas une image valide (formats acceptés : JPEG, PNG).");
        // Fichier avec un mauvais type MIME (ex: texte)
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "document.txt",
                "text/plain",
                "texte simple".getBytes()
        );

        ResponseEntity<String> response = appUserController.putOneUserPhoto(1L, file);

        assertEquals(400, response.getStatusCode().value());
        assertTrue(response.getBody().contains("pas une image valide"));
    }

    @Test
    void testDeletePhotoSuccess() {
        when(appUserRepository.findById(1L)).thenReturn(Optional.of(user));
        when(photoUploader.deletePhoto(eq(1L), any(AppUser.class))).thenReturn(true);

        ResponseEntity<String> response = appUserController.deleteOneUserPhoto(1L);

        assertEquals(200, response.getStatusCode().value());
        assertEquals("Successfully deleted photo", response.getBody());

        verify(photoUploader, times(1)).deletePhoto(eq(1L), any(AppUser.class));
    }
}