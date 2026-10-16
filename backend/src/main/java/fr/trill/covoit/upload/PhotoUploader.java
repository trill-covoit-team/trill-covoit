package fr.trill.covoit.upload;

import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
public class PhotoUploader {
    private static final long MAX_FILE_SIZE = 5242880;
    private final Path photoDirectory = Paths.get("C:\\Users\\rapha\\Documents\\S5\\SAE5\\simulation-serveur-stockage");

    private final AppUserRepository appUserRepository;

    // Injection du repository via le constructeur
    public PhotoUploader(AppUserRepository appUserRepository) {
        this.appUserRepository = appUserRepository;
    }

    public String savePhoto(MultipartFile file, Long userId, AppUser user) throws IOException {
        if (file.isEmpty()) {
            return "Fichier vide.";
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            return "La taille du fichier dépasse la limite autorisée de 5 Mio.";
        }
        String contentType = file.getContentType();
        if (contentType == null || !(contentType.equals("image/jpeg") || contentType.equals("image/png"))) {
            return "Le fichier fourni n'est pas une image valide (formats acceptés : JPEG, PNG).";
        }

        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
        String extension = "";
        int index = originalFileName.lastIndexOf('.');
        if (index > 0) {
            extension = originalFileName.substring(index);
        }

        Files.createDirectories(photoDirectory);

        // Sauvegarde physique
        String fileName = "user_" + userId + extension;
        Path destinationPath = photoDirectory.resolve(fileName);
        file.transferTo(destinationPath);

        // Modification base de données
        String photoUrl = photoDirectory.toString() + "/" + userId;
        user.setPhotoUrl(photoUrl);
        appUserRepository.save(user);

        return "Saved";
    }

    public boolean deletePhoto(Long userId, AppUser user) {
        try {
            boolean fichierSupprime = false;

            // Suppression du fichier physique sur le disque
            if (Files.exists(photoDirectory)) {
                try (var stream = Files.list(photoDirectory)) {
                    Path fichierTrouve = stream
                            .filter(path -> path.getFileName().toString().startsWith("user_" + userId + "."))
                            .findFirst()
                            .orElse(null);

                    if (fichierTrouve != null) {
                        Files.delete(fichierTrouve);
                        fichierSupprime = true;
                    }
                }
            }

            user.setPhotoUrl(null);
            appUserRepository.save(user);

            return fichierSupprime;

        } catch (IOException e) {
            return false;
        }
    }
}
