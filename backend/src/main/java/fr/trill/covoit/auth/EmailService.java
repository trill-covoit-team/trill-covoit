package fr.trill.covoit.auth;

public interface EmailService {

    void sendVerificationCode(String toEmail, String code);
}
