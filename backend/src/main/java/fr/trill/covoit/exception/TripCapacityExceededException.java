package fr.trill.covoit.exception;

public class TripCapacityExceededException extends RuntimeException {
    public TripCapacityExceededException() {
        super("Le nombre de places proposées dépasse le nombre de places disponibles dans ce véhicule.");
    }
}
