package fr.trill.covoit.integration;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.model.Trip;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.model.enums.TripStatus;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.repository.TripRepository;
import fr.trill.covoit.repository.VehicleRepository;
import fr.trill.covoit.service.AccessTokenService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ObjectNode;

import java.time.Instant;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

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
    private TripRepository tripRepository;

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

    private static Stream<Arguments> partialVehicleUpdates() {
        return Stream.of(
                Arguments.of("{\"model\":\" Clio corrigée \"}", "Renault", "Clio corrigée", 4, true),
                Arguments.of("{\"brand\":\" RENAULT \"}", "RENAULT", "Clio", 4, true),
                Arguments.of("{\"passengerCapacity\":2}", "Renault", "Clio", 2, false)
        );
    }

    private static Stream<Arguments> invalidVehicleUpdates() {
        return Stream.of(
                Arguments.of("{}", null),
                Arguments.of("{\"brand\":null}", "brand"),
                Arguments.of("{\"passengerCapacity\":null}", "passengerCapacity"),
                Arguments.of("{\"brand\":\"Peugeot\",\"model\":null}", "model"),
                Arguments.of("{\"brand\":\"   \"}", "brand"),
                Arguments.of("{\"model\":\"" + "A".repeat(101) + "\"}", "model"),
                Arguments.of("{\"passengerCapacity\":0}", "passengerCapacity")
        );
    }

    private static Stream<Arguments> capacityChanges() {
        return Stream.of(
                Arguments.of(TripStatus.PUBLISHED, 2, 409),
                Arguments.of(TripStatus.PUBLISHED, 3, 200),
                Arguments.of(TripStatus.PUBLISHED, 5, 200),
                Arguments.of(TripStatus.COMPLETED, 2, 200),
                Arguments.of(TripStatus.CANCELLED, 2, 200)
        );
    }

    @AfterEach
    void cleanDatabase() {
        tripRepository.deleteAllInBatch();
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

    @ParameterizedTest(name = "{0}")
    @MethodSource("partialVehicleUpdates")
    @DisplayName("Un PATCH partiel modifie uniquement le champ fourni")
    void updateVehicle_WithPartialRequest_UpdatesOnlyProvidedFields(
            String requestBody,
            String expectedBrand,
            String expectedModel,
            int expectedCapacity,
            boolean withPublishedTrip) throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");

        Vehicle vehicle = createVehicle(owner, "Renault", "Clio", 4, true);

        if (withPublishedTrip) {
            createTrip(vehicle, TripStatus.PUBLISHED);
        }

        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        sendPatchRequest(vehicle.getVehicleId(), accessToken, requestBody)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.vehicleId").value(vehicle.getVehicleId()))
                .andExpect(jsonPath("$.brand").value(expectedBrand))
                .andExpect(jsonPath("$.model").value(expectedModel))
                .andExpect(jsonPath("$.passengerCapacity").value(expectedCapacity));

        Vehicle savedVehicle = vehicleRepository.findById(vehicle.getVehicleId())
                .orElseThrow();
        assertThat(savedVehicle.getBrand()).isEqualTo(expectedBrand);
        assertThat(savedVehicle.getModel()).isEqualTo(expectedModel);
        assertThat(savedVehicle.getPassengerCapacity()).isEqualTo(expectedCapacity);
        assertThat(savedVehicle.getUserId()).isEqualTo(owner.getUserId());
        assertThat(savedVehicle.isActive()).isTrue();
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("invalidVehicleUpdates")
    @DisplayName("Un PATCH vide ou invalide est refusé sans modifier le véhicule")
    void updateVehicle_WithInvalidRequest_Returns400WithoutChanges(
            String requestBody, String invalidField) throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");

        Vehicle vehicle = createVehicle(owner, "Renault", "Clio", 4, true);

        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        var response = sendPatchRequest(vehicle.getVehicleId(), accessToken, requestBody)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        if (invalidField != null) {
            response.andExpect(jsonPath("$.fieldErrors." + invalidField).isNotEmpty());
        }

        Vehicle unchangedVehicle = vehicleRepository.findById(vehicle.getVehicleId())
                .orElseThrow();
        assertThat(unchangedVehicle.getBrand()).isEqualTo("Renault");
        assertThat(unchangedVehicle.getModel()).isEqualTo("Clio");
        assertThat(unchangedVehicle.getPassengerCapacity()).isEqualTo(4);
    }

    @ParameterizedTest(name = "{0}, capacité demandée : {1}, HTTP attendu : {2}")
    @MethodSource("capacityChanges")
    @DisplayName("La capacité respecte les places proposées sur tous les trajets non conclus du véhicule")
    void updateVehicle_WithTrips_ChecksOfferedSeatsBeforeChangingCapacity(
            TripStatus tripStatus, int requestedCapacity, int expectedStatus) throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");

        Vehicle vehicle = createVehicle(owner, "Renault", "Clio", 4, true);

        Trip trip = createTrip(vehicle, tripStatus);

        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        var response = sendPatchRequest(vehicle.getVehicleId(), accessToken, """
                {"model": " Clio corrigée ", "passengerCapacity": %d}
                """.formatted(requestedCapacity))
                .andExpect(status().is(expectedStatus));

        Vehicle savedVehicle = vehicleRepository.findById(vehicle.getVehicleId())
                .orElseThrow();

        if (expectedStatus == 409) {
            response.andExpect(jsonPath("$.code").value("VEHICLE_CAPACITY_CONFLICT"));
            assertThat(savedVehicle.getModel()).isEqualTo("Clio");
            assertThat(savedVehicle.getPassengerCapacity()).isEqualTo(4);
        } else {
            response.andExpect(jsonPath("$.passengerCapacity").value(requestedCapacity));
            assertThat(savedVehicle.getModel()).isEqualTo("Clio corrigée");
            assertThat(savedVehicle.getPassengerCapacity()).isEqualTo(requestedCapacity);
        }

        assertThat(tripRepository.findById(trip.getTripId())
                .orElseThrow()
                .getOfferedSeats())
                .isEqualTo(3);
    }

    @ParameterizedTest(name = "{0}")
    @EnumSource(UnavailableVehicle.class)
    @DisplayName("Un véhicule absent, inactif ou appartenant à un autre utilisateur ne peut pas être modifié")
    void updateVehicle_WithUnavailableVehicle_Returns404WithoutChanges(
            UnavailableVehicle unavailable) throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");
        AppUser vehicleOwner = unavailable == UnavailableVehicle.OTHER_OWNER
                ? createVerifiedUser("autre@univ-tlse3.fr") : owner;

        Vehicle vehicle = createVehicle(vehicleOwner, "Renault", "Clio", 4,
                unavailable != UnavailableVehicle.INACTIVE);
        long vehicleId = unavailable == UnavailableVehicle.MISSING
                ? Long.MAX_VALUE : vehicle.getVehicleId();

        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        sendPatchRequest(vehicleId, accessToken, """
                {"model": "Clio corrigée"}
                """)
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("VEHICLE_NOT_FOUND"));

        assertThat(vehicleRepository.findById(vehicle.getVehicleId())
                .orElseThrow()
                .getModel())
                .isEqualTo("Clio");
    }

    @Test
    @DisplayName("La suppression désactive le véhicule et conserve ses trajets terminés ou annulés")
    void deleteVehicle_WithCompletedAndCancelledTrips_Returns204AndDeactivatesVehicle() throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");

        Vehicle vehicle = createVehicle(owner, "Renault", "Clio", 4, true);

        Trip completedTrip = createTrip(vehicle, TripStatus.COMPLETED);
        Trip cancelledTrip = createTrip(vehicle, TripStatus.CANCELLED);

        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        mockMvc.perform(delete(VEHICLES_ENDPOINT + "/" + vehicle.getVehicleId())
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isNoContent())
                .andExpect(content().string(""));

        Vehicle savedVehicle = vehicleRepository.findById(vehicle.getVehicleId())
                .orElseThrow();
        assertThat(savedVehicle.isActive()).isFalse();

        assertThat(tripRepository.findAll())
                .extracting(Trip::getTripId)
                .containsExactlyInAnyOrder(completedTrip.getTripId(), cancelledTrip.getTripId());
    }

    @ParameterizedTest(name = "{0}")
    @EnumSource(UnavailableVehicle.class)
    @DisplayName("Un véhicule absent, inactif ou appartenant à un autre utilisateur ne peut pas être supprimé")
    void deleteVehicle_WithUnavailableVehicle_Returns404WithoutChanges(
            UnavailableVehicle unavailable) throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");
        AppUser vehicleOwner = unavailable == UnavailableVehicle.OTHER_OWNER
                ? createVerifiedUser("autre@univ-tlse3.fr") : owner;

        Vehicle vehicle = createVehicle(vehicleOwner, "Renault", "Clio", 4,
                unavailable != UnavailableVehicle.INACTIVE);
        long vehicleId = unavailable == UnavailableVehicle.MISSING
                ? Long.MAX_VALUE : vehicle.getVehicleId();

        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        mockMvc.perform(delete(VEHICLES_ENDPOINT + "/" + vehicleId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("VEHICLE_NOT_FOUND"));

        Vehicle unchangedVehicle = vehicleRepository.findById(vehicle.getVehicleId())
                .orElseThrow();
        assertThat(unchangedVehicle.isActive()).isEqualTo(vehicle.isActive());
    }

    @Test
    @DisplayName("Un trajet publié bloque la suppression du véhicule")
    void deleteVehicle_WithPublishedTrip_Returns409WithoutDeactivatingVehicle() throws Exception {
        AppUser owner = createVerifiedUser("conducteur@univ-tlse3.fr");

        Vehicle vehicle = createVehicle(owner, "Renault", "Clio", 4, true);

        createTrip(vehicle, TripStatus.PUBLISHED);

        String accessToken = accessTokenService.createAccessToken(owner.getUserId());

        mockMvc.perform(delete(VEHICLES_ENDPOINT + "/" + vehicle.getVehicleId())
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("VEHICLE_IN_USE"));

        assertThat(vehicleRepository.findById(vehicle.getVehicleId())
                .orElseThrow()
                .isActive())
                .isTrue();
    }

    private ResultActions sendPatchRequest(
            long vehicleId, String accessToken, String requestBody) throws Exception {
        return mockMvc.perform(patch(VEHICLES_ENDPOINT + "/" + vehicleId)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody));
    }

    private Trip createTrip(Vehicle vehicle, TripStatus status) {
        return tripRepository.saveAndFlush(Trip.builder()
                .departureAddress("Toulouse")
                .arrivalAddress("Albi")
                .departureDatetime(Instant.now().plusSeconds(86400))
                .offeredSeats(3)
                .status(status)
                .vehicleId(vehicle.getVehicleId())
                .driverId(vehicle.getUserId())
                .build());
    }

    private Vehicle createVehicle(
            AppUser owner, String brand, String model, int passengerCapacity, boolean active) {
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

    private enum UnavailableVehicle {
        MISSING,
        INACTIVE,
        OTHER_OWNER
    }
}
