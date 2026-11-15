package fr.trill.covoit.service;

import fr.trill.covoit.dto.CreateTripRequest;
import fr.trill.covoit.dto.TripResponse;
import fr.trill.covoit.exception.TripCapacityExceededException;
import fr.trill.covoit.exception.TripNotFoundException;
import fr.trill.covoit.exception.VehicleNotFoundException;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.model.Trip;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.model.enums.TripStatus;
import fr.trill.covoit.repository.AppUserRepository;
import fr.trill.covoit.repository.TripRepository;
import fr.trill.covoit.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TripService {

    private final AppUserRepository appUserRepository;
    private final VehicleRepository vehicleRepository;
    private final TripRepository tripRepository;

    private static TripResponse toResponse(Trip trip) {
        return TripResponse.builder()
                .tripId(trip.getTripId())
                .departureAddress(trip.getDepartureAddress())
                .arrivalAddress(trip.getArrivalAddress())
                .departureDatetime(trip.getDepartureDatetime())
                .offeredSeats(trip.getOfferedSeats())
                .status(trip.getStatus())
                .driver(AppUserService.toPublicResponse(trip.getDriver()))
                .vehicle(VehicleService.toResponse(trip.getVehicle()))
                .build();
    }

    @Transactional
    public TripResponse createTrip(Long userId, CreateTripRequest request) {
        Long vehicleId = request.getVehicleId();

        Vehicle vehicle = vehicleRepository.findByVehicleIdAndUserIdAndActiveTrue(vehicleId, userId)
                .orElseThrow(VehicleNotFoundException::new);

        if (request.getOfferedSeats() > vehicle.getPassengerCapacity()) {
            throw new TripCapacityExceededException();
        }

        AppUser driver = appUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Utilisateur introuvable pour le véhicule " + vehicleId));

        Trip trip = Trip.builder()
                .departureAddress(request.getDepartureAddress())
                .arrivalAddress(request.getArrivalAddress())
                .departureDatetime(request.getDepartureDatetime())
                .offeredSeats(request.getOfferedSeats())
                .status(TripStatus.PUBLISHED)
                .vehicle(vehicle)
                .driver(driver)
                .build();

        Trip savedTrip = tripRepository.save(trip);

        return TripService.toResponse(savedTrip);
    }

    @Transactional(readOnly = true)
    public TripResponse getTrip(Long userId, Long tripId) {
        Trip trip = tripRepository.findById(tripId)
                .orElseThrow(TripNotFoundException::new);

        if (trip.getStatus() != TripStatus.PUBLISHED && !trip.getDriver().getUserId().equals(userId)) {
            throw new TripNotFoundException();
        }

        return TripService.toResponse(trip);
    }
}
