package fr.trill.covoit.security;

import lombok.AllArgsConstructor;
import lombok.Getter;
import org.jspecify.annotations.Nullable;
import org.springframework.security.core.CredentialsContainer;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

@AllArgsConstructor
@Getter
public class AppUserPrincipal implements UserDetails, CredentialsContainer {

    private final Long userId;
    private final String email;
    private final boolean emailVerified;
    private @Nullable String passwordHash;

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public @Nullable String getPassword() {
        return passwordHash;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of();
    }

    @Override
    public void eraseCredentials() {
        passwordHash = null;
    }
}
