package fr.trill.covoit.exception;

public class EmptyVehicleUpdateException extends RuntimeException {
    public EmptyVehicleUpdateException() {
        super("Renseignez au moins un champ à modifier.");
    }
}
