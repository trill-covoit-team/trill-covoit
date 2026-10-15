package fr.trill.covoit.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class LoggingEmailService implements EmailService {

    @Override
    public void sendVerificationCode(String to, String code) {
        log.info("==================================================");
        log.info("[EMAIL DE VALIDATION] Destinataire: {}", to);
        log.info("[EMAIL DE VALIDATION] Code de vérification: {}", code);
        log.info("==================================================");
    }
}
