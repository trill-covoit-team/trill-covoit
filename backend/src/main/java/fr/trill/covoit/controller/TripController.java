package fr.trill.covoit.controller;

import fr.trill.covoit.dto.CreateTripRequest;
import fr.trill.covoit.dto.TripResponse;
import fr.trill.covoit.service.TripService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Objects;

@RestController
@RequestMapping("/trips")
@RequiredArgsConstructor
public class TripController {

    private final TripService tripService;

    @PostMapping()
    public ResponseEntity<TripResponse> createTrip(@AuthenticationPrincipal Jwt jwt,
                                                   @Valid @RequestBody CreateTripRequest request) {
        Long userId = Long.valueOf(Objects.requireNonNull(jwt.getSubject()));
        TripResponse response = tripService.createTrip(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}