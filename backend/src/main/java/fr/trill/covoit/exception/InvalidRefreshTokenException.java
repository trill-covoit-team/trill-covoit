package fr.trill.covoit.exception;

public class InvalidRefreshTokenException extends RuntimeException {
    public InvalidRefreshTokenException() {
        super("La session est invalide ou a expiré. Veuillez vous reconnecter.");
    }
}