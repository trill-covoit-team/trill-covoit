package fr.trill.covoit.exception;

public class EmptyUpdateException extends RuntimeException {
    public EmptyUpdateException() {
        super("Renseignez au moins un champ à modifier.");
    }
}
