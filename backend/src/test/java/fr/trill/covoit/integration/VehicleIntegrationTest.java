package fr.trill.covoit.integration;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.repository.VehicleRepository;
import fr.trill.covoit.service.AccessTokenService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ObjectNode;

import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:vehicle-testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL"
})
@AutoConfigureMockMvc
class VehicleIntegrationTest {

    private static final String VEHICLES_ENDPOINT = "/users/me/vehicles";
    private static final String VALID_REQUEST = """
            {"brand": " Renault ", "model": " Clio ", "passengerCapacity": 4}
            """;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private AccessTokenService accessTokenService;

    private static Stream<Arguments> invalidVehicleRequests() {
        String oversizedText = "\"" + "A".repeat(101) + "\"";
        return Stream.of(
                Arguments.of("brand", "null", "VALIDATION_ERROR"),
                Arguments.of("model", "\"   \"", "VALIDATION_ERROR"),
                Arguments.of("brand", oversizedText, "VALIDATION_ERROR"),
                Arguments.of("model", oversizedText, "VALIDATION_ERROR"),
                Arguments.of("passengerCapacity", "null", "VALIDATION_ERROR"),
                Arguments.of("passengerCapacity", "0", "VALIDATION_ERROR"),
                Arguments.of("passengerCapacity", "3.7", "INVALID_REQUEST_BODY")
        );
    }

    @AfterEach
    void cleanDatabase() {
        vehicleRepository.deleteAllInBatch();
        userRepository.deleteAllInBatch();
    }

    @Test
    @DisplayName("La création nettoie les textes et enregistre un véhicule actif pour l'utilisateur connecté")
    void createVehicle_WithValidRequest_Returns201AndPersistsVehicle() throws Exception {
        createVerifiedUser("autre@univ-tlse3.fr");
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");
        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        MvcResult result = mockMvc.perform(post(VEHICLES_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_REQUEST))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.vehicleId").isNumber())
                .andExpect(jsonPath("$.brand").value("Renault"))
                .andExpect(jsonPath("$.model").value("Clio"))
                .andExpect(jsonPath("$.passengerCapacity").value(4))
                .andExpect(jsonPath("$.active").doesNotExist())
                .andExpect(jsonPath("$.userId").doesNotExist())
                .andReturn();

        long vehicleId = objectMapper.readTree(result.getResponse().getContentAsString())
                .get("vehicleId").asLong();
        assertThat(vehicleId).isPositive();
        assertThat(vehicleRepository.count()).isEqualTo(1);
        Vehicle savedVehicle = vehicleRepository.findById(vehicleId).orElseThrow();
        assertThat(savedVehicle.getBrand()).isEqualTo("Renault");
        assertThat(savedVehicle.getModel()).isEqualTo("Clio");
        assertThat(savedVehicle.getPassengerCapacity()).isEqualTo(4);
        assertThat(savedVehicle.getUserId()).isEqualTo(owner.getUserId());
        assertThat(savedVehicle.isActive()).isTrue();
    }

    @ParameterizedTest(name = "{0} = {1}")
    @MethodSource("invalidVehicleRequests")
    @DisplayName("Les données invalides sont refusées sans enregistrer de véhicule")
    void createVehicle_WithInvalidRequest_Returns400WithoutSaving(
            String field, String invalidJsonValue, String expectedCode) throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");
        String accessToken = accessTokenService.createAccessToken(owner.getUserId());
        // Modifier le JSON, et non le DTO, pour tester aussi Jackson et les setters.
        ObjectNode request = objectMapper.readValue(VALID_REQUEST, ObjectNode.class);
        request.set(field, objectMapper.readTree(invalidJsonValue));

        var response = mockMvc.perform(post(VEHICLES_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(expectedCode));

        if ("VALIDATION_ERROR".equals(expectedCode)) {
            response.andExpect(jsonPath("$.fieldErrors." + field).isNotEmpty());
        }
        assertThat(vehicleRepository.count()).isZero();
    }

    @Test
    @DisplayName("Une requête sans authentification est refusée sans enregistrer de véhicule")
    void createVehicle_WithoutToken_Returns401WithoutSaving() throws Exception {
        mockMvc.perform(post(VEHICLES_ENDPOINT)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_REQUEST))
                .andExpect(status().isUnauthorized());

        assertThat(vehicleRepository.count()).isZero();
    }

    @Test
    @DisplayName("La liste contient uniquement les véhicules actifs de l'utilisateur, par identifiant croissant")
    void getUserVehicles_WithMixedVehicles_ReturnsOnlyActiveVehiclesForCurrentUser() throws Exception {
        AppUser otherUser = createVerifiedUser("autre@univ-tlse3.fr");
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle firstVehicle = createVehicle(owner, "Renault", "Clio", 4, true);
        createVehicle(owner, "Renault", "Megane", 4, false);
        createVehicle(otherUser, "Peugeot", "208", 3, true);
        Vehicle secondVehicle = createVehicle(owner, "Toyota", "Yaris", 3, true);
        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        mockMvc.perform(get(VEHICLES_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].vehicleId").value(firstVehicle.getVehicleId()))
                .andExpect(jsonPath("$[0].brand").value("Renault"))
                .andExpect(jsonPath("$[0].model").value("Clio"))
                .andExpect(jsonPath("$[0].passengerCapacity").value(4))
                .andExpect(jsonPath("$[1].vehicleId").value(secondVehicle.getVehicleId()))
                .andExpect(jsonPath("$[1].brand").value("Toyota"))
                .andExpect(jsonPath("$[1].model").value("Yaris"))
                .andExpect(jsonPath("$[1].passengerCapacity").value(3));
    }

    @Test
    @DisplayName("Un utilisateur sans véhicule actif reçoit une liste vide")
    void getUserVehicles_WithoutActiveVehicles_Returns200AndEmptyList() throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");
        AppUser otherUser = createVerifiedUser("autre@univ-tlse3.fr");
        createVehicle(owner, "Renault", "Clio", 4, false);
        createVehicle(otherUser, "Peugeot", "208", 3, true);
        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        mockMvc.perform(get(VEHICLES_ENDPOINT)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    private Vehicle createVehicle(AppUser owner, String brand, String model,
                                  int passengerCapacity, boolean active) {
        return vehicleRepository.saveAndFlush(Vehicle.builder()
                .userId(owner.getUserId())
                .brand(brand)
                .model(model)
                .passengerCapacity(passengerCapacity)
                .active(active)
                .build());
    }

    private AppUser createVerifiedUser(String email) {
        return userRepository.saveAndFlush(AppUser.builder()
                .email(email)
                .passwordHash("mot-de-passe-non-utilise-dans-ce-test")
                .emailVerified(true)
                .termsAccepted(true)
                .build());
    }
}
