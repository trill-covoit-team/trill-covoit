package fr.trill.covoit.auth.exception;

public class EmailNotVerifiedException extends RuntimeException {

    public EmailNotVerifiedException(String message) {
        super(message); // 403 forbidden
    }
}
