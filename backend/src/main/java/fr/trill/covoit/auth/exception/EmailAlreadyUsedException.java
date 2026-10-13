package fr.trill.covoit.auth.exception;

public class EmailAlreadyUsedException extends RuntimeException {

    public EmailAlreadyUsedException(String message) {
        super(message); // 409 conflict
    }
}
