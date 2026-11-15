package fr.trill.covoit.repository;

import fr.trill.covoit.model.Trip;
import fr.trill.covoit.model.Vehicle;
import fr.trill.covoit.model.enums.TripStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TripRepository extends JpaRepository<Trip, Long> {

    boolean existsByVehicleAndStatusAndOfferedSeatsGreaterThan(
            Vehicle vehicle, TripStatus status, Integer capacity);

    boolean existsByVehicleAndStatus(Vehicle vehicle, TripStatus status);
}
