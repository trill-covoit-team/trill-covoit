package fr.trill.covoit.dto;

import fr.trill.covoit.dto.validation.MaxUtf8Bytes;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {

    @NotBlank(message = "L'adresse email est obligatoire.")
    @Email(message = "L'adresse email est invalide.")
    @Size(max = 255, message = "L'adresse email ne doit pas dépasser 255 caractères.")
    private String email;

    @NotBlank(message = "Le mot de passe est obligatoire.")
    @Size(min = 8, message = "Le mot de passe doit contenir au moins 8 caractères.")
    @MaxUtf8Bytes
    private String password;

    @AssertTrue(message = "Vous devez accepter les conditions d'utilisation.")
    private boolean termsAccepted;
}
