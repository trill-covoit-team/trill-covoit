package fr.trill.covoit.auth;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class LoggingEmailService implements EmailService {

    @Override
    public void sendVerificationCode(String toEmail, String code) {
        log.info("=================================================");
        log.info("[EMAIL SIMULATION] Envoi du code de validation à {}", toEmail);
        log.info("[EMAIL SIMULATION] Code : {}", code);
        log.info("=================================================");
    }
}
