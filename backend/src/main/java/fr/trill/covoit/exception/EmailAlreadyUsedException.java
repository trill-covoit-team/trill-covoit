package fr.trill.covoit.exception;

public class EmailAlreadyUsedException extends RuntimeException {
    public EmailAlreadyUsedException() {
        super("Cette adresse email est déjà utilisée.");
    }
}
