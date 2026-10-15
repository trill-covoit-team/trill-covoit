package fr.trill.covoit.exception;

public class EmailNotVerifiedException extends RuntimeException {
    public EmailNotVerifiedException() {
        super("Veuillez valider votre adresse email avant de vous connecter.");
    }
}
