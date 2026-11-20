package fr.trill.covoit.dto;

import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@NoArgsConstructor
public class CreateTripRequest {

    @NotNull(message = "L'identifiant du véhicule est obligatoire.")
    @Positive(message = "L'identifiant du véhicule doit être un entier positif.")
    private Long vehicleId;

    @NotBlank(message = "L'adresse de départ est obligatoire.")
    @Size(max = 255, message = "L'adresse de départ ne doit pas dépasser 255 caractères.")
    private String departureAddress;

    @NotBlank(message = "L'adresse d'arrivée est obligatoire.")
    @Size(max = 255, message = "L'adresse d'arrivée ne doit pas dépasser 255 caractères.")
    private String arrivalAddress;

    @NotNull(message = "La date et l'heure de départ sont obligatoires.")
    @Future(message = "La date et l'heure de départ doivent être dans le futur.")
    private Instant departureDatetime;

    @NotNull(message = "Le nombre de places proposées est obligatoire.")
    @Positive(message = "Le nombre de places proposées doit être un entier positif.")
    private Integer offeredSeats;

    public void setDepartureAddress(String departureAddress) {
        this.departureAddress = departureAddress == null ? null : departureAddress.strip();
    }

    public void setArrivalAddress(String arrivalAddress) {
        this.arrivalAddress = arrivalAddress == null ? null : arrivalAddress.strip();
    }
}
