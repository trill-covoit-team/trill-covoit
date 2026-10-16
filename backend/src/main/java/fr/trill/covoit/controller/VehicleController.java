package fr.trill.covoit.controller;

import fr.trill.covoit.service.VehicleService;
import jakarta.validation.Valid;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.dto.VehicleRequest;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/users/me/vehicles")
public class VehicleController {

    private final VehicleService service;

    public VehicleController(VehicleService service){
        this.service = service;
    }

    // GET /users/me/vehicles
    @GetMapping
    public ResponseEntity<?> getAll() {
        List<Vehicle> vehicles = service.getAll();

        if (vehicles.isEmpty()) {
            return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body("Vous n'avez aucun vehicule enregistré");
        }

        return ResponseEntity.ok(vehicles);
    }

    // POST /users/me/vehicles
    @PostMapping
    public ResponseEntity<?> insert(@Valid @RequestBody VehicleRequest request) {
        Vehicle vehicle = service.insert(request);
        return ResponseEntity.ok(vehicle);
        
    }

    // PUT /users/me/vehicles
    @PutMapping(params = "/{id}")
    public ResponseEntity<?> update(
            @RequestParam String idString,
            @Valid @RequestBody VehicleRequest request) {
        try {
            int id = Integer.parseInt(idString);

            if (id <= 0) {
                return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body("L'id du vehicule doit être un entier positif");
            }

            Optional<Vehicle> vehicle = service.update(id, request);

            if (vehicle.isEmpty()) {
                return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body("Aucun vehicule trouvé pour cette id");
            }

            return ResponseEntity.ok(vehicle.get());

        } catch (NumberFormatException e) {
            return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body("L'id du vehicule doit être un entier positif");
        }
        
    }
    
}
