package fr.trill.covoit.controller;

import fr.trill.covoit.dto.CreateVehicleRequest;
import fr.trill.covoit.dto.UpdateVehicleRequest;
import fr.trill.covoit.dto.VehicleResponse;
import fr.trill.covoit.service.VehicleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users/me/vehicles")
@RequiredArgsConstructor
public class VehicleController {

    private final VehicleService vehicleService;

    @PostMapping
    public ResponseEntity<VehicleResponse> createVehicle(@AuthenticationPrincipal Jwt jwt,
                                                         @Valid @RequestBody CreateVehicleRequest request) {
        String userId = jwt.getSubject();
        VehicleResponse response = vehicleService.createVehicle(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<VehicleResponse>> getUserVehicles(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getSubject();
        List<VehicleResponse> response = vehicleService.getUserVehicles(userId);
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

    @PatchMapping("/{vehicleId}")
    public ResponseEntity<VehicleResponse> updateVehicle(@AuthenticationPrincipal Jwt jwt,
                                                         @PathVariable Long vehicleId,
                                                         @Valid @RequestBody UpdateVehicleRequest request) {
        String userId = jwt.getSubject();
        VehicleResponse response = vehicleService.updateVehicle(userId, vehicleId, request);
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }
}
