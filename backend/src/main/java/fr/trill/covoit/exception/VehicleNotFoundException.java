package fr.trill.covoit.exception;

public class VehicleNotFoundException extends RuntimeException {
    public VehicleNotFoundException() {
        super("Le véhicule n'existe pas.");
    }
}
