package fr.trill.covoit.security;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AppUserDetailsService implements UserDetailsService {

    private final AppUserRepository appUserRepository;

    @Override
    public UserDetails loadUserByUsername(String email) {
        AppUser user = appUserRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new UsernameNotFoundException("Aucun compte ne correspond à cette adresse email."));

        return new AppUserPrincipal(user.getUserId(), user.getEmail(), user.isEmailVerified(), user.getPasswordHash());
    }
}
