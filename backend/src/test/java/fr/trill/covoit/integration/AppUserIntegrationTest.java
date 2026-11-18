package fr.trill.covoit.integration;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.service.AccessTokenService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.ObjectMapper;

import java.util.Map;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:app-user-testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL"
})
@AutoConfigureMockMvc
class AppUserIntegrationTest {

    private static final String PROFILE_ENDPOINT = "/users/me";
    private static final String EXISTING_PHOTO_URL = "https://example.test/avatar.png";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private AppUserRepository userRepository;
    @Autowired
    private AccessTokenService accessTokenService;

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

    @AfterEach
    void cleanDatabase() {
        userRepository.deleteAllInBatch();
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
        };

        mockMvc.perform(request.header(HttpHeaders.AUTHORIZATION, bearerToken(deletedUser)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTHENTICATED_USER_NOT_FOUND"));

        assertThat(userRepository.count()).isZero();
    }

    @ParameterizedTest(name = "photo présente : {0}")
    @ValueSource(booleans = {false, true})
    @DisplayName("Le GET expose uniquement le profil du compte connecté avec son URL de photo éventuelle")
    void getMyProfile_WithAnotherAccount_ReturnsOnlyCurrentProfile(boolean withPhoto) throws Exception {
        createUser("autre@univ-tlse3.fr");
        AppUser owner = createUser("profil@univ-tlse3.fr");
        if (withPhoto) {
            owner.setPhotoUrl(EXISTING_PHOTO_URL);
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
                .andExpect(jsonPath("$.photoUrl").value(owner.getPhotoUrl()))
                .andExpect(jsonPath("$.passwordHash").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.verificationCode").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.verificationCodeExpiresAt").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.emailVerified").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.termsAccepted").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.updatedAt").doesNotHaveJsonPath());
    }

    @Test
    @DisplayName("Un PATCH complet nettoie les textes et conserve les autres données et comptes")
    void updateMyProfile_WithValidRequest_Returns200AndPersistsCleanedFields() throws Exception {
        AppUser otherUser = createUser("autre@univ-tlse3.fr");
        AppUser owner = createUser("profil@univ-tlse3.fr");
        owner.setPhotoUrl(EXISTING_PHOTO_URL);
        userRepository.saveAndFlush(owner);
        owner = reload(owner);

        sendPatch(owner, """
                {"firstName":" Alice ","lastName":" Dupont ","bio":" Une nouvelle bio. "}
                """)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Alice"))
                .andExpect(jsonPath("$.lastName").value("Dupont"))
                .andExpect(jsonPath("$.bio").value("Une nouvelle bio."))
                .andExpect(jsonPath("$.photoUrl").value(owner.getPhotoUrl()));

        AppUser savedUser = reload(owner);
        assertThat(savedUser.getFirstName()).isEqualTo("Alice");
        assertThat(savedUser.getLastName()).isEqualTo("Dupont");
        assertThat(savedUser.getBio()).isEqualTo("Une nouvelle bio.");
        assertThat(savedUser).usingRecursiveComparison()
                .ignoringFields("firstName", "lastName", "bio", "updatedAt")
                .isEqualTo(owner);
        assertUnchanged(otherUser);
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

    private AppUser reload(AppUser user) {
        return userRepository.findById(user.getUserId()).orElseThrow();
    }

    private void assertUnchanged(AppUser user) {
        assertThat(reload(user)).usingRecursiveComparison().isEqualTo(user);
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

    private enum UserAction {
        GET_PROFILE,
        PATCH_PROFILE
    }
}
