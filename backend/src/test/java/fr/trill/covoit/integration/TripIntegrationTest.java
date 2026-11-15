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
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ObjectNode;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:trip-testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL"
})
@AutoConfigureMockMvc
class TripIntegrationTest {

    private static final String TRIPS_ENDPOINT = "/trips";

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
    @Autowired
    private PlatformTransactionManager transactionManager;

    private static Stream<Arguments> invalidTripRequests() {
        String oversizedAddress = "\"" + "A".repeat(256) + "\"";
        return Stream.of(
                Arguments.of("vehicleId", "null", "VALIDATION_ERROR"),
                Arguments.of("vehicleId", "0", "VALIDATION_ERROR"),
                Arguments.of("departureAddress", "\"   \"", "VALIDATION_ERROR"),
                Arguments.of("arrivalAddress", "\"   \"", "VALIDATION_ERROR"),
                Arguments.of("departureAddress", oversizedAddress, "VALIDATION_ERROR"),
                Arguments.of("arrivalAddress", oversizedAddress, "VALIDATION_ERROR"),
                Arguments.of("offeredSeats", "null", "VALIDATION_ERROR"),
                Arguments.of("offeredSeats", "0", "VALIDATION_ERROR"),
                Arguments.of("departureDatetime", "null", "VALIDATION_ERROR"),
                Arguments.of("departureDatetime", "\"demain\"", "INVALID_REQUEST_BODY"),
                Arguments.of("offeredSeats", "2.5", "INVALID_REQUEST_BODY")
        );
    }

    private static Stream<Arguments> allowedTripReads() {
        return Stream.of(
                Arguments.of(TripStatus.PUBLISHED, true),
                Arguments.of(TripStatus.PUBLISHED, false),
                Arguments.of(TripStatus.CANCELLED, true),
                Arguments.of(TripStatus.COMPLETED, true)
        );
    }

    @AfterEach
    void cleanDatabase() {
        tripRepository.deleteAllInBatch();
        vehicleRepository.deleteAllInBatch();
        userRepository.deleteAllInBatch();
    }

    @ParameterizedTest(name = "{0} places proposées sur 4")
    @ValueSource(ints = {3, 4})
    @DisplayName("La création enregistre le trajet et renvoie uniquement les informations publiques")
    void createTrip_WithValidRequest_Returns201AndPersistsTrip(int offeredSeats) throws Exception {
        createVerifiedUser("autre@univ-tlse3.fr");
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);
        Instant departure = futureDeparture();
        ObjectNode request = validRequest(vehicle.getVehicleId(), departure);
        request.put("offeredSeats", offeredSeats);

        var result = sendRequest(driver, request)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tripId").isNumber())
                .andExpect(jsonPath("$.departureAddress").value("Toulouse"))
                .andExpect(jsonPath("$.arrivalAddress").value("Albi"))
                .andExpect(jsonPath("$.offeredSeats").value(offeredSeats))
                .andExpect(jsonPath("$.status").value("PUBLISHED"))
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        long tripId = response.get("tripId").asLong();
        assertThat(tripId).isPositive();
        assertThat(Instant.parse(response.get("departureDatetime").asString())).isEqualTo(departure);
        assertPublicDriver(response.get("driver"), driver);
        JsonNode responseVehicle = response.get("vehicle");
        assertThat(responseVehicle.get("vehicleId").asLong()).isEqualTo(vehicle.getVehicleId());
        assertThat(responseVehicle.get("brand").asString()).isEqualTo("Renault");
        assertThat(responseVehicle.get("model").asString()).isEqualTo("Clio");
        assertThat(responseVehicle.get("passengerCapacity").asInt()).isEqualTo(4);

        assertThat(tripRepository.count()).isEqualTo(1);
        assertPersistedTrip(tripId, driver, vehicle, departure, offeredSeats, "Toulouse", "Albi");
    }

    @Test
    @DisplayName("Les adresses de 255 caractères sont acceptées et conservées")
    void createTrip_WithMaximumLengthAddresses_Returns201AndPreservesAddresses() throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);
        Instant departure = futureDeparture();
        String departureAddress = "D".repeat(255);
        String arrivalAddress = "A".repeat(255);
        ObjectNode request = validRequest(vehicle.getVehicleId(), departure);
        request.put("departureAddress", departureAddress);
        request.put("arrivalAddress", arrivalAddress);

        var result = sendRequest(driver, request)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.departureAddress").value(departureAddress))
                .andExpect(jsonPath("$.arrivalAddress").value(arrivalAddress))
                .andReturn();

        long tripId = objectMapper.readTree(result.getResponse().getContentAsString()).get("tripId").asLong();
        assertThat(tripRepository.count()).isEqualTo(1);
        assertPersistedTrip(tripId, driver, vehicle, departure, 3, departureAddress, arrivalAddress);
    }

    @Test
    @DisplayName("Proposer une place de trop est refusé sans créer de trajet")
    void createTrip_WithTooManySeats_Returns409WithoutSaving() throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);
        ObjectNode request = validRequest(vehicle.getVehicleId(), futureDeparture());
        request.put("offeredSeats", 5);

        sendRequest(driver, request)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TRIP_CAPACITY_EXCEEDED"));

        assertThat(tripRepository.count()).isZero();
    }

    @ParameterizedTest(name = "{0}")
    @EnumSource(UnavailableVehicle.class)
    @DisplayName("Un véhicule absent, inactif ou appartenant à un autre utilisateur est refusé")
    void createTrip_WithUnavailableVehicle_Returns404WithoutSaving(UnavailableVehicle unavailable) throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        AppUser owner = unavailable == UnavailableVehicle.OTHER_OWNER
                ? createVerifiedUser("autre@univ-tlse3.fr") : driver;
        Vehicle vehicle = createVehicle(owner, unavailable != UnavailableVehicle.INACTIVE);
        long vehicleId = unavailable == UnavailableVehicle.MISSING ? Long.MAX_VALUE : vehicle.getVehicleId();

        sendRequest(driver, validRequest(vehicleId, futureDeparture()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("VEHICLE_NOT_FOUND"));

        assertThat(tripRepository.count()).isZero();
    }

    @ParameterizedTest(name = "{0} = {1}")
    @MethodSource("invalidTripRequests")
    @DisplayName("Les contraintes du DTO sont appliquées avant toute création")
    void createTrip_WithInvalidRequest_Returns400WithoutSaving(
            String field, String invalidJsonValue, String expectedCode) throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);
        ObjectNode request = validRequest(vehicle.getVehicleId(), futureDeparture());
        request.set(field, objectMapper.readTree(invalidJsonValue));

        var response = sendRequest(driver, request)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(expectedCode));

        if ("VALIDATION_ERROR".equals(expectedCode)) {
            response.andExpect(jsonPath("$.fieldErrors." + field).isNotEmpty());
        }

        assertThat(tripRepository.count()).isZero();
    }

    @Test
    @DisplayName("Un départ passé est refusé avec une erreur sur la date")
    void createTrip_WithPastDeparture_Returns400WithoutSaving() throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);

        sendRequest(driver, validRequest(vehicle.getVehicleId(), Instant.now().minus(2, ChronoUnit.DAYS)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.departureDatetime").isNotEmpty());

        assertThat(tripRepository.count()).isZero();
    }

    @Test
    @DisplayName("La création exige une authentification")
    void createTrip_WithoutToken_Returns401WithoutSaving() throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);

        mockMvc.perform(post(TRIPS_ENDPOINT)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest(vehicle.getVehicleId(), futureDeparture()))))
                .andExpect(status().isUnauthorized());

        assertThat(tripRepository.count()).isZero();
    }

    @ParameterizedTest(name = "statut : {0}, lecteur conducteur : {1}")
    @MethodSource("allowedTripReads")
    @DisplayName("Un trajet publié est consultable par tous les utilisateurs connectés, les autres par leur conducteur")
    void getTrip_WithAllowedUser_Returns200AndTrip(TripStatus tripStatus, boolean readerIsDriver) throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        AppUser reader = readerIsDriver ? driver : createVerifiedUser("lecteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);
        Trip trip = createTrip(driver, vehicle, tripStatus);
        String accessToken = accessTokenService.createAccessToken(reader.getUserId());

        var result = mockMvc.perform(get(TRIPS_ENDPOINT + "/" + trip.getTripId())
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tripId").value(trip.getTripId()))
                .andExpect(jsonPath("$.departureAddress").value("Toulouse"))
                .andExpect(jsonPath("$.arrivalAddress").value("Albi"))
                .andExpect(jsonPath("$.offeredSeats").value(3))
                .andExpect(jsonPath("$.status").value(tripStatus.name()))
                .andExpect(jsonPath("$.driver.userId").value(driver.getUserId()))
                .andExpect(jsonPath("$.driver.firstName").value(driver.getFirstName()))
                .andExpect(jsonPath("$.vehicle.vehicleId").value(vehicle.getVehicleId()))
                .andExpect(jsonPath("$.vehicle.brand").value("Renault"))
                .andExpect(jsonPath("$.vehicle.model").value("Clio"))
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(Instant.parse(response.get("departureDatetime").asString())).isEqualTo(trip.getDepartureDatetime());
    }

    @ParameterizedTest(name = "{0}")
    @EnumSource(value = TripStatus.class, names = {"CANCELLED", "COMPLETED"})
    @DisplayName("Un trajet annulé ou terminé est masqué aux autres utilisateurs")
    void getTrip_WithOtherUserAndUnpublishedTrip_Returns404(TripStatus tripStatus) throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        AppUser reader = createVerifiedUser("lecteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);
        Trip trip = createTrip(driver, vehicle, tripStatus);
        String accessToken = accessTokenService.createAccessToken(reader.getUserId());

        mockMvc.perform(get(TRIPS_ENDPOINT + "/" + trip.getTripId())
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("TRIP_NOT_FOUND"));
    }

    @Test
    @DisplayName("Un identifiant de trajet inexistant renvoie une erreur 404")
    void getTrip_WithMissingTrip_Returns404() throws Exception {
        AppUser reader = createVerifiedUser("lecteur@univ-tlse3.fr");
        String accessToken = accessTokenService.createAccessToken(reader.getUserId());

        mockMvc.perform(get(TRIPS_ENDPOINT + "/" + Long.MAX_VALUE)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("TRIP_NOT_FOUND"));
    }

    @Test
    @DisplayName("Même un trajet publié exige une authentification pour être consulté")
    void getTrip_WithoutToken_Returns401() throws Exception {
        AppUser driver = createVerifiedUser("conducteur@univ-tlse3.fr");
        Vehicle vehicle = createVehicle(driver, true);
        Trip trip = createTrip(driver, vehicle, TripStatus.PUBLISHED);

        mockMvc.perform(get(TRIPS_ENDPOINT + "/" + trip.getTripId()))
                .andExpect(status().isUnauthorized());
    }

    private Trip createTrip(AppUser driver, Vehicle vehicle, TripStatus status) {
        return tripRepository.saveAndFlush(Trip.builder()
                .departureAddress("Toulouse")
                .arrivalAddress("Albi")
                .departureDatetime(futureDeparture())
                .offeredSeats(3)
                .status(status)
                .driver(driver)
                .vehicle(vehicle)
                .build());
    }

    private void assertPublicDriver(JsonNode response, AppUser driver) {
        assertThat(response.propertyNames()).containsExactlyInAnyOrder(
                "userId", "firstName", "lastName", "photoUrl", "bio", "createdAt");
        assertThat(response.get("userId").asLong()).isEqualTo(driver.getUserId());
        assertThat(response.get("firstName").asString()).isEqualTo(driver.getFirstName());
        assertThat(response.get("lastName").asString()).isEqualTo(driver.getLastName());
        assertThat(response.get("photoUrl").asString()).isEqualTo(driver.getPhotoUrl());
        assertThat(response.get("bio").asString()).isEqualTo(driver.getBio());
        // Relire la valeur persistée : la base peut arrondir la précision de @PrePersist.
        Instant createdAt = userRepository.findById(driver.getUserId()).orElseThrow().getCreatedAt();
        assertThat(Instant.parse(response.get("createdAt").asString())).isEqualTo(createdAt);
    }

    private void assertPersistedTrip(long tripId, AppUser driver, Vehicle vehicle, Instant departure,
                                     int offeredSeats, String departureAddress, String arrivalAddress) {
        // Les relations LAZY nécessitent une transaction pour être consultées.
        // Elle démarre après la requête pour vérifier les données enregistrées
        // sans englober l'appel du service dans la transaction du test.
        TransactionTemplate readTransaction = new TransactionTemplate(transactionManager);
        readTransaction.setReadOnly(true);
        readTransaction.executeWithoutResult(transaction -> {
            Trip saved = tripRepository.findById(tripId).orElseThrow();
            assertThat(saved.getDepartureAddress()).isEqualTo(departureAddress);
            assertThat(saved.getArrivalAddress()).isEqualTo(arrivalAddress);
            assertThat(saved.getDepartureDatetime()).isEqualTo(departure);
            assertThat(saved.getOfferedSeats()).isEqualTo(offeredSeats);
            assertThat(saved.getStatus()).isEqualTo(TripStatus.PUBLISHED);
            assertThat(saved.getDriver().getUserId()).isEqualTo(driver.getUserId());
            assertThat(saved.getDriver().getEmail()).isEqualTo(driver.getEmail());
            assertThat(saved.getVehicle().getVehicleId()).isEqualTo(vehicle.getVehicleId());
            assertThat(saved.getVehicle().getModel()).isEqualTo(vehicle.getModel());
        });
    }

    private ResultActions sendRequest(AppUser driver, ObjectNode request) throws Exception {
        return mockMvc.perform(post(TRIPS_ENDPOINT)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessTokenService.createAccessToken(driver.getUserId()))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)));
    }

    private ObjectNode validRequest(long vehicleId, Instant departure) {
        return objectMapper.createObjectNode()
                .put("vehicleId", vehicleId)
                .put("departureAddress", "  Toulouse  ")
                .put("arrivalAddress", "  Albi  ")
                .put("departureDatetime", departure.toString())
                .put("offeredSeats", 3);
    }

    private Instant futureDeparture() {
        // Une date fixe finirait par être passée ; deux jours laissent une marge d'exécution.
        // La précision à la seconde évite les écarts d'arrondi lors du stockage en base.
        return Instant.now().plus(2, ChronoUnit.DAYS).truncatedTo(ChronoUnit.SECONDS);
    }

    private Vehicle createVehicle(AppUser owner, boolean active) {
        return vehicleRepository.saveAndFlush(Vehicle.builder()
                .userId(owner.getUserId())
                .brand("Renault")
                .model("Clio")
                .passengerCapacity(4)
                .active(active)
                .build());
    }

    private AppUser createVerifiedUser(String email) {
        return userRepository.saveAndFlush(AppUser.builder()
                .email(email)
                .passwordHash("hash-prive-reserve-au-test")
                .emailVerified(true)
                .termsAccepted(true)
                .firstName("Camille")
                .lastName("Martin")
                .photoUrl("https://example.com/profil.jpg")
                .bio("Conducteur entre Toulouse et Albi")
                .verificationCode("123456")
                .verificationCodeExpiresAt(futureDeparture())
                .build());
    }

    private enum UnavailableVehicle {
        MISSING,
        INACTIVE,
        OTHER_OWNER
    }
}
