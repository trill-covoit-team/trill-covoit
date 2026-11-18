package fr.trill.covoit.integration;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.service.AccessTokenService;
import fr.trill.covoit.service.AppUserService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:app-user-testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
        "app.public-base-url=https://api.example.test/api/"
})
@AutoConfigureMockMvc
class AppUserIntegrationTest {

    private static final String PROFILE_ENDPOINT = "/users/me";
    private static final String PHOTO_ENDPOINT = PROFILE_ENDPOINT + "/photo";
    private static final String PHOTO_URL_PREFIX = "https://api.example.test/api/photos/";

    @TempDir
    static Path photoDirectory;
    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private AppUserRepository userRepository;
    @Autowired
    private AccessTokenService accessTokenService;
    @Autowired
    private AppUserService appUserService;
    @Autowired
    private PlatformTransactionManager transactionManager;

    @DynamicPropertySource
    static void configurePhotoStorage(DynamicPropertyRegistry registry) {
        registry.add("app.photo.storage-directory", () -> photoDirectory.toString());
    }

    private static Stream<Arguments> partialProfileUpdates() {
        return Stream.of(
                Arguments.of("{\"firstName\":\" Alice \"}", "Alice", "Martin", "Bio initiale."),
                Arguments.of("{\"lastName\":\" Dupont \"}", "Camille", "Dupont", "Bio initiale."),
                Arguments.of("{\"bio\":\" Une nouvelle bio. \"}", "Camille", "Martin", "Une nouvelle bio.")
        );
    }

    private static Stream<Arguments> clearedProfileFields() {
        return Stream.of(
                Arguments.of("lastName", "", null, "Bio initiale."),
                Arguments.of("lastName", "   ", null, "Bio initiale."),
                Arguments.of("bio", "", "Martin", null),
                Arguments.of("bio", "   ", "Martin", null)
        );
    }

    private static Stream<Arguments> validProfileBoundaries() {
        return Stream.of(
                Arguments.of("Al", "N", "B"),
                Arguments.of("A".repeat(100), "N".repeat(100), "B".repeat(500))
        );
    }

    private static Stream<Arguments> invalidProfileUpdates() {
        return Stream.of(
                Arguments.of("{}", null),
                Arguments.of("{\"firstName\":null}", "firstName"),
                Arguments.of("{\"lastName\":null}", "lastName"),
                Arguments.of("{\"bio\":null}", "bio"),
                Arguments.of("{\"firstName\":\"\"}", "firstName"),
                Arguments.of("{\"firstName\":\"   \"}", "firstName"),
                Arguments.of("{\"firstName\":\" A \"}", "firstName"),
                Arguments.of("{\"firstName\":\"" + "A".repeat(101) + "\"}", "firstName"),
                Arguments.of("{\"lastName\":\"" + "N".repeat(101) + "\"}", "lastName"),
                Arguments.of("{\"bio\":\"" + "B".repeat(501) + "\"}", "bio"),
                Arguments.of("{\"firstName\":\"Alice\",\"lastName\":null}", "lastName")
        );
    }

    private static Stream<Arguments> validPhotos() {
        return Stream.of(
                Arguments.of("png", "avatar.png", "image/png", "png"),
                Arguments.of("jpeg", "avatar.jpeg", "image/jpeg", "jpg"),
                Arguments.of("jpeg", "avatar.png", "image/png", "jpg")
        );
    }

    private static Stream<Arguments> invalidPhotos() throws IOException {
        byte[] png = imageBytes("png", 2, 2);
        return Stream.of(
                Arguments.of("vide", new byte[0]),
                Arguments.of("texte", "Ceci n'est pas une image.".getBytes(StandardCharsets.UTF_8)),
                Arguments.of("GIF", imageBytes("gif", 2, 2)),
                // L'en-tête PNG contient les dimensions, mais les pixels sont absents.
                Arguments.of("PNG tronqué", Arrays.copyOf(png, 33))
        );
    }

    private static MockMultipartFile photo(
            String format, String fileName, String contentType, int width, int height) throws IOException {
        return new MockMultipartFile("file", fileName, contentType, imageBytes(format, width, height));
    }

    private static byte[] imageBytes(String format, int width, int height) throws IOException {
        var bytes = new ByteArrayOutputStream();
        if (!ImageIO.write(new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB), format, bytes)) {
            throw new IllegalArgumentException("Format d'image de test inconnu : " + format);
        }
        return bytes.toByteArray();
    }

    @AfterEach
    void cleanDatabaseAndPhotos() throws IOException {
        userRepository.deleteAllInBatch();
        try (var files = Files.list(photoDirectory)) {
            for (Path file : files.toList()) {
                Files.delete(file);
            }
        }
    }

    @Test
    @DisplayName("Le profil refuse une requête sans access token")
    void getMyProfile_WithoutToken_Returns401() throws Exception {
        mockMvc.perform(get(PROFILE_ENDPOINT))
                .andExpect(status().isUnauthorized());
    }

    @ParameterizedTest(name = "{0}")
    @EnumSource(UserAction.class)
    @DisplayName("Les opérations refusent un JWT valide dont le compte n'existe plus")
    void userAction_WithDeletedAccount_Returns401WithoutChanges(UserAction action) throws Exception {
        AppUser deletedUser = createUser("supprime@univ-tlse3.fr");
        userRepository.deleteById(deletedUser.getUserId());

        var request = switch (action) {
            case GET_PROFILE -> get(PROFILE_ENDPOINT);
            case PATCH_PROFILE -> patch(PROFILE_ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"bio\":\"Nouvelle bio.\"}");
            case PUT_PHOTO -> multipart(HttpMethod.PUT, PHOTO_ENDPOINT)
                    .file(photo("png", "avatar.png", "image/png", 2, 2));
            case DELETE_PHOTO -> delete(PHOTO_ENDPOINT);
        };

        mockMvc.perform(request.header(HttpHeaders.AUTHORIZATION, bearerToken(deletedUser)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTHENTICATED_USER_NOT_FOUND"));

        assertThat(userRepository.count()).isZero();
        assertThat(photoFileNames()).isEmpty();
    }

    @ParameterizedTest(name = "photo présente : {0}")
    @ValueSource(booleans = {false, true})
    @DisplayName("Le GET expose uniquement le profil du compte connecté et construit son URL de photo")
    void getMyProfile_WithAnotherAccount_ReturnsOnlyCurrentProfile(boolean withPhoto) throws Exception {
        createUser("autre@univ-tlse3.fr");
        AppUser owner = createUser("profil@univ-tlse3.fr");
        if (withPhoto) {
            owner.setPhotoFileName("existing.png");
            userRepository.saveAndFlush(owner);
        }

        mockMvc.perform(get(PROFILE_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, bearerToken(owner)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(owner.getUserId()))
                .andExpect(jsonPath("$.email").value(owner.getEmail()))
                .andExpect(jsonPath("$.firstName").value(owner.getFirstName()))
                .andExpect(jsonPath("$.lastName").value(owner.getLastName()))
                .andExpect(jsonPath("$.bio").value(owner.getBio()))
                .andExpect(jsonPath("$.createdAt").value(owner.getCreatedAt().toString()))
                .andExpect(jsonPath("$.photoUrl").value(withPhoto
                        ? PHOTO_URL_PREFIX + owner.getPhotoFileName() : null))
                .andExpect(jsonPath("$.passwordHash").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.verificationCode").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.verificationCodeExpiresAt").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.emailVerified").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.termsAccepted").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.photoFileName").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.updatedAt").doesNotHaveJsonPath());
    }

    @Test
    @DisplayName("Un PATCH complet nettoie les textes et conserve les autres données et comptes")
    void updateMyProfile_WithValidRequest_Returns200AndPersistsCleanedFields() throws Exception {
        AppUser otherUser = createUser("autre@univ-tlse3.fr");
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));

        sendPatch(owner, """
                {"firstName":" Alice ","lastName":" Dupont ","bio":" Une nouvelle bio. "}
                """)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Alice"))
                .andExpect(jsonPath("$.lastName").value("Dupont"))
                .andExpect(jsonPath("$.bio").value("Une nouvelle bio."))
                .andExpect(jsonPath("$.photoUrl").value(PHOTO_URL_PREFIX + owner.getPhotoFileName()));

        AppUser savedUser = reload(owner);
        assertThat(savedUser.getFirstName()).isEqualTo("Alice");
        assertThat(savedUser.getLastName()).isEqualTo("Dupont");
        assertThat(savedUser.getBio()).isEqualTo("Une nouvelle bio.");
        assertThat(savedUser).usingRecursiveComparison()
                .ignoringFields("firstName", "lastName", "bio", "updatedAt")
                .isEqualTo(owner);
        assertUnchanged(otherUser);
        assertThat(photoFileNames()).containsExactly(owner.getPhotoFileName());
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("partialProfileUpdates")
    @DisplayName("Un PATCH partiel modifie seulement le champ fourni")
    void updateMyProfile_WithPartialRequest_UpdatesOnlyProvidedField(
            String requestBody, String firstName, String lastName, String bio) throws Exception {
        AppUser owner = createUser("profil@univ-tlse3.fr");

        sendPatch(owner, requestBody)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value(firstName))
                .andExpect(jsonPath("$.lastName").value(lastName))
                .andExpect(jsonPath("$.bio").value(bio));

        AppUser savedUser = reload(owner);
        assertThat(savedUser.getFirstName()).isEqualTo(firstName);
        assertThat(savedUser.getLastName()).isEqualTo(lastName);
        assertThat(savedUser.getBio()).isEqualTo(bio);
    }

    @ParameterizedTest(name = "{0} = [{1}]")
    @MethodSource("clearedProfileFields")
    @DisplayName("Une chaîne vide ou blanche efface le nom ou la bio")
    void updateMyProfile_WithEmptyOptionalField_ClearsOnlyThatField(
            String field, String value, String lastName, String bio) throws Exception {
        AppUser owner = createUser("profil@univ-tlse3.fr");

        sendPatch(owner, objectMapper.writeValueAsString(Map.of(field, value)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$." + field).value(nullValue()));

        AppUser savedUser = reload(owner);
        assertThat(savedUser.getLastName()).isEqualTo(lastName);
        assertThat(savedUser.getBio()).isEqualTo(bio);
        assertThat(savedUser).usingRecursiveComparison().ignoringFields(field, "updatedAt").isEqualTo(owner);
    }

    @ParameterizedTest(name = "bornes valides, cas {index}")
    @MethodSource("validProfileBoundaries")
    @DisplayName("Les longueurs minimales et maximales retenues sont acceptées")
    void updateMyProfile_AtValidLengthBoundaries_Returns200(
            String firstName, String lastName, String bio) throws Exception {
        AppUser owner = createUser("profil@univ-tlse3.fr");

        sendPatch(owner, objectMapper.writeValueAsString(Map.of(
                "firstName", firstName, "lastName", lastName, "bio", bio)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value(firstName))
                .andExpect(jsonPath("$.lastName").value(lastName))
                .andExpect(jsonPath("$.bio").value(bio));

        AppUser savedUser = reload(owner);
        assertThat(savedUser.getFirstName()).isEqualTo(firstName);
        assertThat(savedUser.getLastName()).isEqualTo(lastName);
        assertThat(savedUser.getBio()).isEqualTo(bio);
    }

    @ParameterizedTest(name = "cas {index}, champ : {1}")
    @MethodSource("invalidProfileUpdates")
    @DisplayName("Un PATCH vide ou invalide est refusé sans aucune modification partielle")
    void updateMyProfile_WithInvalidRequest_Returns400WithoutChanges(
            String requestBody, String invalidField) throws Exception {
        AppUser owner = createUser("profil@univ-tlse3.fr");

        var response = sendPatch(owner, requestBody)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        if (invalidField != null) {
            response.andExpect(jsonPath("$.fieldErrors." + invalidField).isNotEmpty());
        }

        assertUnchanged(owner);
    }

    @ParameterizedTest(name = "contenu {0}, nom {1}, type déclaré {2}")
    @MethodSource("validPhotos")
    @DisplayName("Le PUT enregistre les octets JPEG ou PNG et détermine l'extension par leur contenu")
    void updatePhoto_WithValidImage_Returns200AndStoresOriginalBytes(
            String format, String originalName, String contentType, String expectedExtension) throws Exception {
        AppUser owner = createUser("profil@univ-tlse3.fr");
        MockMultipartFile file = photo(format, originalName, contentType, 2, 2);

        var response = sendPhoto(owner, file).andExpect(status().isOk());

        AppUser savedUser = reload(owner);
        String fileName = savedUser.getPhotoFileName();
        assertThat(fileName).endsWith("." + expectedExtension).doesNotContain("/", "\\");
        assertThat(Files.readAllBytes(photoDirectory.resolve(fileName))).isEqualTo(file.getBytes());
        response.andExpect(jsonPath("$.photoUrl").value(PHOTO_URL_PREFIX + fileName));
        assertOnlyPhotoChanged(owner, savedUser);
        assertThat(photoFileNames()).containsExactly(fileName);
    }

    @ParameterizedTest(name = "PNG vers {0}")
    @ValueSource(strings = {"png", "jpeg"})
    @DisplayName("Le remplacement supprime l'ancien fichier après confirmation et préserve les autres photos")
    void updatePhoto_WithExistingPhoto_ReplacesFileAndDatabaseReference(String format) throws Exception {
        AppUser otherUser = seedPhoto(createUser("autre@univ-tlse3.fr"));
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));

        var response = sendPhoto(owner, photo(format, "avatar." + format, "image/" + format, 2, 2))
                .andExpect(status().isOk());

        AppUser savedUser = reload(owner);
        assertThat(savedUser.getPhotoFileName()).isNotEqualTo(owner.getPhotoFileName());
        assertThat(photoDirectory.resolve(owner.getPhotoFileName())).doesNotExist();
        assertThat(photoDirectory.resolve(savedUser.getPhotoFileName())).exists();
        response.andExpect(jsonPath("$.photoUrl").value(PHOTO_URL_PREFIX + savedUser.getPhotoFileName()));
        assertOnlyPhotoChanged(owner, savedUser);
        assertUnchanged(otherUser);
        assertThat(photoFileNames()).containsExactlyInAnyOrder(savedUser.getPhotoFileName(), otherUser.getPhotoFileName());
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("invalidPhotos")
    @DisplayName("Une photo vide, non reconnue, non autorisée ou indécodable conserve la photo précédente")
    void updatePhoto_WithInvalidImage_Returns400WithoutChanges(String scenario, byte[] bytes) throws Exception {
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));
        byte[] previousBytes = Files.readAllBytes(photoDirectory.resolve(owner.getPhotoFileName()));

        sendPhoto(owner, new MockMultipartFile("file", "avatar.png", "image/png", bytes))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_PHOTO"));

        assertUnchanged(owner);
        assertThat(photoFileNames()).containsExactly(owner.getPhotoFileName());
        assertThat(Files.readAllBytes(photoDirectory.resolve(owner.getPhotoFileName()))).isEqualTo(previousBytes);
    }

    @ParameterizedTest(name = "{0} × {1}")
    @CsvSource({"4096, 1", "1, 4096"})
    @DisplayName("Une largeur ou une hauteur de 4 096 pixels est acceptée")
    void updatePhoto_AtDimensionLimits_Returns200(int width, int height) throws Exception {
        AppUser owner = createUser("profil@univ-tlse3.fr");

        sendPhoto(owner, photo("png", "avatar.png", "image/png", width, height))
                .andExpect(status().isOk());

        assertThat(photoFileNames()).containsExactly(reload(owner).getPhotoFileName());
    }

    @ParameterizedTest(name = "{0} × {1}")
    @CsvSource({"4097, 1", "1, 4097"})
    @DisplayName("Une largeur ou une hauteur excessive est refusée sans modifier la photo")
    void updatePhoto_OverDimensionLimits_Returns400WithoutChanges(int width, int height) throws Exception {
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));

        sendPhoto(owner, photo("png", "avatar.png", "image/png", width, height))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_PHOTO"));

        assertUnchanged(owner);
        assertThat(photoFileNames()).containsExactly(owner.getPhotoFileName());
    }

    @Test
    @DisplayName("Un formulaire sans partie file est refusé sans modifier la photo")
    void updatePhoto_WithoutFilePart_Returns400WithoutChanges() throws Exception {
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));

        mockMvc.perform(multipart(HttpMethod.PUT, PHOTO_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, bearerToken(owner)))
                .andExpect(status().isBadRequest());

        assertUnchanged(owner);
        assertThat(photoFileNames()).containsExactly(owner.getPhotoFileName());
    }

    @ParameterizedTest(name = "fichier présent : {0}")
    @ValueSource(booleans = {true, false})
    @DisplayName("Le DELETE efface la référence et le fichier éventuel sans affecter l'autre compte")
    void deletePhoto_WithStoredReference_Returns204AndRemovesPhoto(boolean fileExists) throws Exception {
        AppUser otherUser = seedPhoto(createUser("autre@univ-tlse3.fr"));
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));
        if (!fileExists) {
            Files.delete(photoDirectory.resolve(owner.getPhotoFileName()));
        }

        sendDelete(owner).andExpect(status().isNoContent()).andExpect(content().string(""));

        AppUser savedUser = reload(owner);
        assertThat(savedUser.getPhotoFileName()).isNull();
        assertOnlyPhotoChanged(owner, savedUser);
        assertUnchanged(otherUser);
        assertThat(photoFileNames()).containsExactly(otherUser.getPhotoFileName());
    }

    @Test
    @DisplayName("Le DELETE sans photo peut être répété sans modifier le profil")
    void deletePhoto_WithoutPhoto_RepeatedlyReturns204WithoutChanges() throws Exception {
        AppUser owner = createUser("profil@univ-tlse3.fr");

        sendDelete(owner).andExpect(status().isNoContent()).andExpect(content().string(""));
        sendDelete(owner).andExpect(status().isNoContent()).andExpect(content().string(""));

        assertUnchanged(owner);
        assertThat(photoFileNames()).isEmpty();
    }

    @Test
    @DisplayName("Le rollback d'un remplacement conserve l'ancienne photo et nettoie la nouvelle")
    void updatePhoto_WhenTransactionRollsBack_RestoresReferenceAndDeletesNewFile() throws Exception {
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));
        MockMultipartFile file = photo("jpeg", "avatar.jpeg", "image/jpeg", 2, 2);

        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
            appUserService.updatePhoto(owner.getUserId(), file);
            userRepository.flush();

            String newFileName = reload(owner).getPhotoFileName();
            assertThat(newFileName).isNotEqualTo(owner.getPhotoFileName());
            assertThat(photoDirectory.resolve(newFileName)).exists();
            assertThat(photoDirectory.resolve(owner.getPhotoFileName())).exists();
            status.setRollbackOnly();
        });

        assertUnchanged(owner);
        assertThat(photoFileNames()).containsExactly(owner.getPhotoFileName());
    }

    @Test
    @DisplayName("Le rollback d'un DELETE conserve la référence et le fichier")
    void deletePhoto_WhenTransactionRollsBack_PreservesReferenceAndFile() throws Exception {
        AppUser owner = seedPhoto(createUser("profil@univ-tlse3.fr"));

        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
            appUserService.deletePhoto(owner.getUserId());
            userRepository.flush();

            assertThat(reload(owner).getPhotoFileName()).isNull();
            assertThat(photoDirectory.resolve(owner.getPhotoFileName())).exists();
            status.setRollbackOnly();
        });

        assertUnchanged(owner);
        assertThat(photoFileNames()).containsExactly(owner.getPhotoFileName());
    }

    private AppUser createUser(String email) {
        AppUser user = userRepository.saveAndFlush(AppUser.builder()
                .email(email)
                .passwordHash("mot-de-passe-non-utilise-dans-ce-test")
                .emailVerified(true)
                .termsAccepted(true)
                .firstName("Camille")
                .lastName("Martin")
                .bio("Bio initiale.")
                .build());
        return reload(user);
    }

    private AppUser seedPhoto(AppUser user) throws IOException {
        String fileName = "user_" + user.getUserId() + "_existing.png";
        Files.write(photoDirectory.resolve(fileName), imageBytes("png", 2, 2));
        user.setPhotoFileName(fileName);
        userRepository.saveAndFlush(user);
        return reload(user);
    }

    private AppUser reload(AppUser user) {
        return userRepository.findById(user.getUserId()).orElseThrow();
    }

    private void assertUnchanged(AppUser user) {
        assertThat(reload(user)).usingRecursiveComparison().isEqualTo(user);
    }

    private void assertOnlyPhotoChanged(AppUser previousUser, AppUser savedUser) {
        assertThat(savedUser).usingRecursiveComparison()
                .ignoringFields("photoFileName", "updatedAt")
                .isEqualTo(previousUser);
    }

    private List<String> photoFileNames() throws IOException {
        try (var files = Files.list(photoDirectory)) {
            return files.map(path -> path.getFileName().toString()).toList();
        }
    }

    private String bearerToken(AppUser user) {
        return "Bearer " + accessTokenService.createAccessToken(user.getUserId());
    }

    private ResultActions sendPatch(AppUser user, String requestBody) throws Exception {
        return mockMvc.perform(patch(PROFILE_ENDPOINT)
                .header(HttpHeaders.AUTHORIZATION, bearerToken(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody));
    }

    private ResultActions sendPhoto(AppUser user, MockMultipartFile file) throws Exception {
        return mockMvc.perform(multipart(HttpMethod.PUT, PHOTO_ENDPOINT)
                .header(HttpHeaders.AUTHORIZATION, bearerToken(user))
                .file(file));
    }

    private ResultActions sendDelete(AppUser user) throws Exception {
        return mockMvc.perform(delete(PHOTO_ENDPOINT)
                .header(HttpHeaders.AUTHORIZATION, bearerToken(user)));
    }

    private enum UserAction {
        GET_PROFILE,
        PATCH_PROFILE,
        PUT_PHOTO,
        DELETE_PHOTO
    }
}
