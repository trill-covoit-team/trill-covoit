package fr.trill.covoit.service;

public interface EmailService {
    void sendVerificationCode(String to, String code);
}
