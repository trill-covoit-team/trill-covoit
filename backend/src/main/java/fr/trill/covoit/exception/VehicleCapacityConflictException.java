package fr.trill.covoit.exception;

public class VehicleCapacityConflictException extends RuntimeException {
    public VehicleCapacityConflictException() {
        super("Un trajet non terminé propose plus de places que le nombre indiqué pour ce véhicule.");
    }
}
