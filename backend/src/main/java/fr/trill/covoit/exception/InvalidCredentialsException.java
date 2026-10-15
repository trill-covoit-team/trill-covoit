package fr.trill.covoit.exception;

public class InvalidCredentialsException extends RuntimeException {
    public InvalidCredentialsException() {
        super("L'adresse email ou le mot de passe est incorrect.");
    }
}
