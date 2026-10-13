package fr.trill.covoit.repository;

import fr.trill.covoit.model.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VehicleRepository extends JpaRepository<Vehicle, Integer>{}
