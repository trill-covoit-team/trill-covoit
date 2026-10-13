package fr.trill.covoit.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyEmailRequest {

    @NotBlank(message = "L'adresse email est requise")
    @Email(message = "L'adresse email n'est pas valide")
    private String email;

    @NotBlank(message = "Le code de validation est requis")
    @Pattern(regexp = "^[0-9]{6}$", message = "Le code de validation doit comporter 6 chiffres")
    private String code;
}
