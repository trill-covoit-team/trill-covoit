package fr.trill.covoit.auth.exception;

public class InvalidVerificationCodeException extends RuntimeException {

    public InvalidVerificationCodeException(String message) {
        super(message); // 400 bad request
    }
}
