package fr.trill.covoit.exception;

public class AuthenticatedUserNotFoundException extends RuntimeException {
    public AuthenticatedUserNotFoundException() {
        super("Votre compte est introuvable. Veuillez vous reconnecter.");
    }
}
