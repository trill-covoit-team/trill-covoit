package fr.trill.covoit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data 
@Builder
@NoArgsConstructor
@AllArgsConstructor 
public class VehicleRequest {
    
    private String brand;
    private String model;
    private int passengerCapacity;
    private int userId;
    private String status;
}
