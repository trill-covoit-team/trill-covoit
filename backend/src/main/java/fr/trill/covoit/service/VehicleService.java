package fr.trill.covoit.service;

import fr.trill.covoit.dto.CreateVehicleRequest;
import fr.trill.covoit.dto.VehicleResponse;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;

    public VehicleResponse createVehicle(String userId, CreateVehicleRequest request) {
        Vehicle vehicle = Vehicle.builder()
                .brand(request.getBrand())
                .model(request.getModel())
                .passengerCapacity(request.getPassengerCapacity())
                .userId(Long.valueOf(userId))
                .build();

        Vehicle savedVehicle = vehicleRepository.save(vehicle);

        return VehicleResponse.builder()
                .vehicleId(savedVehicle.getVehicleId())
                .brand(vehicle.getBrand())
                .model(vehicle.getModel())
                .passengerCapacity(vehicle.getPassengerCapacity())
                .build();
    }
}
