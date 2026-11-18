package fr.trill.covoit.dto;

import com.fasterxml.jackson.annotation.JsonSetter;
import com.fasterxml.jackson.annotation.Nulls;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UpdateAppUserRequest {

    // Un null explicite est refusé.
    @JsonSetter(nulls = Nulls.FAIL)
    @Size(min = 2, max = 100, message = "Le prénom doit contenir entre 2 et 100 caractères.")
    private String firstName;

    @JsonSetter(nulls = Nulls.FAIL)
    @Size(max = 100, message = "Le nom ne doit pas dépasser 100 caractères.")
    private String lastName;

    @JsonSetter(nulls = Nulls.FAIL)
    @Size(max = 500, message = "La bio ne doit pas dépasser 500 caractères.")
    private String bio;

    public void setFirstName(String firstName) {
        this.firstName = firstName == null ? null : firstName.strip();
    }

    public void setLastName(String lastName) {
        this.lastName = lastName == null ? null : lastName.strip();
    }

    public void setBio(String bio) {
        this.bio = bio == null ? null : bio.strip();
    }
}