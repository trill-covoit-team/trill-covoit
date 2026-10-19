package fr.trill.covoit.controller;

import fr.trill.covoit.dto.MessageResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest; // Assurez-vous d'importer votre DTO pour le patch
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.service.AppUserService; // On mocke le service appelé par le contrôleur
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
public class AppUserControllerTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private MockMvc mockMvc;
    @Mock
    private AppUserService appUserService;
    @InjectMocks
    private AppUserController appUserController;
    private AppUser user;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(appUserController)
                .setControllerAdvice(new IllegalArgumentException()) // ou votre gestionnaire d'exceptions global
                .build();

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
    void testGetOneUserFound() throws Exception {
        // getOneUser renvoie directement l'AppUser (ou lève une exception)
        when(appUserService.getOneUser(1L)).thenReturn(user);

        mockMvc.perform(get("/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Marc"));
    }

    @Test
    void testGetOneUserNotFound() throws Exception {
        when(appUserService.getOneUser(4L)).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Utilisateur non trouvé"));

        mockMvc.perform(get("/users/4"))
                .andExpect(status().isNotFound());
    }

    @Test
    void testPatchOneUser() throws Exception {
        UpdateAppUserRequest request = new UpdateAppUserRequest();
        request.setFirstName("ryad");
        request.setBio("Attention changement bio");

        // Le service renvoie un MessageResponse
        when(appUserService.patchOneUser(eq(1L), any())).thenReturn(new MessageResponse("Saved"));

        mockMvc.perform(patch("/users/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Saved")); // Si MessageResponse possède un champ "message", adaptez selon votre DTO

        verify(appUserService, times(1)).patchOneUser(eq(1L), any());
    }

    @Test
    void testUploadPhotoSuccess() throws Exception {
        when(appUserService.saveUserPhoto(eq(1L), any())).thenReturn(new MessageResponse("Saved"));

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "avatar.png",
                "image/png",
                "contenu-image".getBytes()
        );

        mockMvc.perform(multipart(HttpMethod.PUT, "/users/1/photo").file(file))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Saved"));

        verify(appUserService, times(1)).saveUserPhoto(eq(1L), any());
    }

    @Test
    void testUploadPhotoInvalidType() throws Exception {
        // Le service lève une IllegalArgumentException si le fichier n'est pas valide
        when(appUserService.saveUserPhoto(eq(1L), any()))
                .thenThrow(new IllegalArgumentException("Le fichier fourni n'est pas une image valide (formats acceptés : JPEG, PNG)."));

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "document.txt",
                "text/plain",
                "texte simple".getBytes()
        );

        mockMvc.perform(multipart(HttpMethod.PUT, "/users/1/photo").file(file))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(containsString("pas une image valide")));
    }

    @Test
    void testDeletePhotoSuccess() throws Exception {
        when(appUserService.deleteUserPhoto(1L)).thenReturn(new MessageResponse("Successfully deleted photo"));

        mockMvc.perform(delete("/users/1/photo"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Successfully deleted photo"));

        verify(appUserService, times(1)).deleteUserPhoto(1L);
    }
}