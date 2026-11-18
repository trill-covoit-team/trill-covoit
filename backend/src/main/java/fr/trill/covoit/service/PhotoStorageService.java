package fr.trill.covoit.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Service
public class PhotoStorageService {

    private final Path photoDirectory;

    public PhotoStorageService(@Value("${app.photo.storage-directory}") String directory) {
        this.photoDirectory = Path.of(directory).toAbsolutePath().normalize();
    }

    public void storePhoto(String fileName, MultipartFile file) {
        try {
            Files.createDirectories(photoDirectory);
            file.transferTo(photoDirectory.resolve(fileName));
        } catch (IOException exception) {
            throw new UncheckedIOException("Impossible d’enregistrer la photo.", exception);
        }
    }

    public void deletePhoto(String fileName) {
        Path photoPath = photoDirectory.resolve(fileName).normalize();
        if (!photoDirectory.equals(photoPath.getParent())) {
            throw new IllegalArgumentException("Le nom du fichier est invalide.");
        }

        try {
            Files.deleteIfExists(photoPath);
        } catch (IOException exception) {
            throw new UncheckedIOException("Impossible de supprimer la photo.", exception);
        }
    }
}
