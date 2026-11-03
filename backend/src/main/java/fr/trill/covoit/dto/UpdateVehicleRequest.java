package fr.trill.covoit.dto;

import com.fasterxml.jackson.annotation.JsonSetter;
import com.fasterxml.jackson.annotation.Nulls;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UpdateVehicleRequest {

    // En PATCH, un champ absent reste inchangé ; un null explicite est refusé.
    @JsonSetter(nulls = Nulls.FAIL)
    @Size(min = 1, max = 100, message = "La marque du véhicule doit contenir entre 1 et 100 caractères.")
    private String brand;

    @JsonSetter(nulls = Nulls.FAIL)
    @Size(min = 1, max = 100, message = "Le modèle du véhicule doit contenir entre 1 et 100 caractères.")
    private String model;

    @JsonSetter(nulls = Nulls.FAIL)
    @Positive(message = "Le nombre de places du véhicule doit être un entier positif.")
    private Integer passengerCapacity;

    public void setBrand(String brand) {
        this.brand = brand == null ? null : brand.strip();
    }

    public void setModel(String model) {
        this.model = model == null ? null : model.strip();
    }
}
