package fr.trill.covoit.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CreateVehicleRequest {

    @NotBlank(message = "La marque du véhicule est obligatoire.")
    @Size(max = 100, message = "La marque du véhicule ne doit pas dépasser 100 caractères.")
    private String brand;

    @NotBlank(message = "Le modèle du véhicule est obligatoire.")
    @Size(max = 100, message = "Le modèle du véhicule ne doit pas dépasser 100 caractères.")
    private String model;

    @NotNull(message = "Le nombre de places du véhicule est obligatoire.")
    @Positive(message = "Le nombre de places du véhicule doit être un entier positif.")
    private Integer passengerCapacity;

    public void setBrand(String brand) {
        this.brand = brand == null ? null : brand.strip();
    }

    public void setModel(String model) {
        this.model = model == null ? null : model.strip();
    }
}
