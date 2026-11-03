package fr.trill.covoit.repository;

import fr.trill.covoit.model.Vehicle;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

    List<Vehicle> findAllByUserIdAndActiveTrueOrderByVehicleIdAsc(Long userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<Vehicle> findByVehicleIdAndUserIdAndActiveTrue(Long vehicleId, Long userId);
}
