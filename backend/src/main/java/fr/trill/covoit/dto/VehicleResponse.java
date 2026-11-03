package fr.trill.covoit.dto;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@JsonPropertyOrder({"vehicleId", "brand", "model", "passengerCapacity"})
public class VehicleResponse {

    private Long vehicleId;
    private String brand;
    private String model;
    private Integer passengerCapacity;
}
