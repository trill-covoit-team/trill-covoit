package fr.trill.covoit.exception;

public class InvalidVerificationCodeException extends RuntimeException {
    public InvalidVerificationCodeException() {
        super("Le code de validation est invalide ou expiré.");
    }
}
