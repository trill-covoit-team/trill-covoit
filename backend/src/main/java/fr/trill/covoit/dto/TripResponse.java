package fr.trill.covoit.dto;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import fr.trill.covoit.model.enums.TripStatus;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;

@Getter
@Builder
@JsonPropertyOrder({
        "tripId", "departureAddress", "arrivalAddress", "departureDatetime",
        "offeredSeats", "status", "driver", "vehicle"
})
public class TripResponse {

    private Long tripId;
    private String departureAddress;
    private String arrivalAddress;
    private Instant departureDatetime;
    private Integer offeredSeats;
    private TripStatus status;
    private PublicUserResponse driver;
    private VehicleResponse vehicle;
}
