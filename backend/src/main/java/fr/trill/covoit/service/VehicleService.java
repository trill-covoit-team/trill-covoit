package fr.trill.covoit.service;

import org.springframework.stereotype.Service;

import fr.trill.covoit.repository.VehicleRepository;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.dto.VehicleRequest;

import java.util.List;
import java.util.Optional;

@Service 
public class VehicleService {

    private final VehicleRepository repository;

    public VehicleService(VehicleRepository repository) {
        this.repository = repository;
    }

    // GET all my vehicle
    public List<Vehicle> getAll() {
        return repository.findAll();
        // TODO Il faudrat modifier cette ligne pour renvoyer uniquement les vehicules de l'utilisateur
    }

    // POST vehicle
    public Vehicle insert(VehicleRequest request) {
        // Set properties of Vehicle
        Vehicle vehicle = new Vehicle();
        vehicle.setBrand(request.getBrand());
        vehicle.setModel(request.getModel());
        vehicle.setPassengerCapacity(request.getPassengerCapacity());
        vehicle.setStatus(request.getStatus());
        vehicle.setUserId(request.getUserId());
        // TODO Il faudrat modifier cette ligne pour récupéré l'id de session de l'utilisateur

        return repository.save(vehicle);
    }

    public Optional<Vehicle> update(int id, VehicleRequest request) {
        Optional<Vehicle> optionalVehicle = repository.findById(id);

        if (optionalVehicle.isEmpty()) {
            return Optional.empty();
        }

        Vehicle vehicle = optionalVehicle.get();
        // Set properties of vehicle based on request
        vehicle.setBrand(request.getBrand());
        vehicle.setModel(request.getModel());
        vehicle.setPassengerCapacity(request.getPassengerCapacity());
        vehicle.setStatus(request.getStatus());

        return Optional.of(repository.save(vehicle));
    }
    
}
