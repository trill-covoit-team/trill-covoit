package fr.trill.covoit.exception;

public class VehicleInUseException extends RuntimeException {
    public VehicleInUseException() {
        super("Ce véhicule est associé à un trajet non terminé.");
    }
}
