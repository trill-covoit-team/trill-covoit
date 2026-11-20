package fr.trill.covoit.exception;

public class TripNotFoundException extends RuntimeException {
    public TripNotFoundException() {
        super("Le trajet n'existe pas.");
    }
}
