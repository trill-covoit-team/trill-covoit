package fr.trill.covoit.service;

import fr.trill.covoit.dto.CreateVehicleRequest;
import fr.trill.covoit.dto.VehicleResponse;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;

    private static VehicleResponse toResponse(Vehicle vehicle) {
        return VehicleResponse.builder()
                .vehicleId(vehicle.getVehicleId())
                .brand(vehicle.getBrand())
                .model(vehicle.getModel())
                .passengerCapacity(vehicle.getPassengerCapacity())
                .build();
    }

    @Transactional
    public VehicleResponse createVehicle(String userId, CreateVehicleRequest request) {
        Vehicle vehicle = Vehicle.builder()
                .brand(request.getBrand())
                .model(request.getModel())
                .passengerCapacity(request.getPassengerCapacity())
                .userId(Long.valueOf(userId))
                .build();

        Vehicle savedVehicle = vehicleRepository.save(vehicle);

        return VehicleService.toResponse(savedVehicle);
    }

    @Transactional(readOnly = true)
    public List<VehicleResponse> getUserVehicles(String userId) {
        List<Vehicle> vehicles = vehicleRepository.findAllByUserIdAndActiveTrueOrderByVehicleIdAsc(Long.valueOf(userId));

        return vehicles.stream()
                .map(VehicleService::toResponse)
                .toList();
    }
}
