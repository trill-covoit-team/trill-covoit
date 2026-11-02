package fr.trill.covoit.service;

import fr.trill.covoit.dto.CreateVehicleRequest;
import fr.trill.covoit.dto.UpdateVehicleRequest;
import fr.trill.covoit.dto.VehicleResponse;
import fr.trill.covoit.exception.EmptyVehicleUpdateException;
import fr.trill.covoit.exception.VehicleCapacityConflictException;
import fr.trill.covoit.exception.VehicleInUseException;
import fr.trill.covoit.exception.VehicleNotFoundException;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.model.enums.TripStatus;
import fr.trill.covoit.repository.TripRepository;
import fr.trill.covoit.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final TripRepository tripRepository;

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

    @Transactional
    public VehicleResponse updateVehicle(String userId, Long vehicleId, UpdateVehicleRequest request) {
        if (request.getBrand() == null && request.getModel() == null && request.getPassengerCapacity() == null) {
            throw new EmptyVehicleUpdateException();
        }

        Vehicle vehicle = vehicleRepository.findByVehicleIdAndUserIdAndActiveTrue(vehicleId, Long.valueOf(userId))
                .orElseThrow(VehicleNotFoundException::new);

        // Le véhicule doit conserver assez de places pour les trajets publiés.
        // Les trajets terminés ou annulés ne bloquent pas la modification du véhicule.
        if (request.getPassengerCapacity() != null
                && tripRepository.existsByVehicleIdAndStatusAndOfferedSeatsGreaterThan(
                vehicleId, TripStatus.PUBLISHED, request.getPassengerCapacity())) {
            throw new VehicleCapacityConflictException();
        }

        if (request.getBrand() != null) {
            vehicle.setBrand(request.getBrand());
        }

        if (request.getModel() != null) {
            vehicle.setModel(request.getModel());
        }

        if (request.getPassengerCapacity() != null) {
            vehicle.setPassengerCapacity(request.getPassengerCapacity());
        }

        Vehicle updatedVehicle = vehicleRepository.save(vehicle);

        return VehicleService.toResponse(updatedVehicle);
    }

    @Transactional
    public void deleteVehicle(String userId, Long vehicleId) {
        Vehicle vehicle = vehicleRepository.findByVehicleIdAndUserIdAndActiveTrue(vehicleId, Long.valueOf(userId))
                .orElseThrow(VehicleNotFoundException::new);

        if (tripRepository.existsByVehicleIdAndStatus(vehicleId, TripStatus.PUBLISHED)) {
            throw new VehicleInUseException();
        }

        vehicle.setActive(false);
        vehicleRepository.save(vehicle);
    }
}
