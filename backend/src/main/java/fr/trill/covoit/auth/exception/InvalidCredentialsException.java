package fr.trill.covoit.auth.exception;

public class InvalidCredentialsException extends RuntimeException {

    public InvalidCredentialsException(String message) {
        super(message); // 401 Unauthorized
    }
}
