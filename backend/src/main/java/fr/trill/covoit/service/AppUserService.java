package fr.trill.covoit.service;

import fr.trill.covoit.dto.MyProfileResponse;
import fr.trill.covoit.dto.PublicUserResponse;
import fr.trill.covoit.dto.UpdateAppUserRequest;
import fr.trill.covoit.exception.AuthenticatedUserNotFoundException;
import fr.trill.covoit.exception.EmptyUpdateException;
import fr.trill.covoit.exception.InvalidPhotoException;
import fr.trill.covoit.model.AppUser;
import fr.trill.covoit.repository.AppUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import javax.imageio.stream.MemoryCacheImageInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.Iterator;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AppUserService {

    private static final int MAX_PHOTO_WIDTH = 4096;
    private static final int MAX_PHOTO_HEIGHT = 4096;

    private final AppUserRepository appUserRepository;
    private final PhotoStorageService photoStorageService;
    private final PhotoUrlBuilder photoUrlBuilder;

    public PublicUserResponse toPublicResponse(AppUser user) {
        return PublicUserResponse.builder()
                .userId(user.getUserId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .photoUrl(photoUrlBuilder.build(user.getPhotoFileName()))
                .bio(user.getBio())
                .createdAt(user.getCreatedAt())
                .build();
    }

    private MyProfileResponse toMyProfileResponse(AppUser user) {
        return MyProfileResponse.builder()
                .userId(user.getUserId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .photoUrl(photoUrlBuilder.build(user.getPhotoFileName()))
                .bio(user.getBio())
                .createdAt(user.getCreatedAt())
                .build();
    }

    @Transactional(readOnly = true)
    public MyProfileResponse getMyProfile(Long userId) {
        AppUser user = getAuthenticatedUser(userId);
        return toMyProfileResponse(user);
    }

    @Transactional
    public MyProfileResponse updateMyProfile(Long userId, UpdateAppUserRequest request) {
        if (request.getFirstName() == null && request.getLastName() == null && request.getBio() == null) {
            throw new EmptyUpdateException();
        }

        AppUser user = getAuthenticatedUser(userId);

        // Un champ absent reste inchangé ; une chaîne vide efface le nom ou la bio.
        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName().isEmpty() ? null : request.getLastName());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio().isEmpty() ? null : request.getBio());
        }

        AppUser savedUser = appUserRepository.save(user);

        return toMyProfileResponse(savedUser);
    }

    @Transactional
    public MyProfileResponse updatePhoto(Long userId, MultipartFile file) {
        // Deux remplacements simultanés doivent lire successivement la photo courante.
        AppUser user = appUserRepository.findByUserId(userId)
                .orElseThrow(AuthenticatedUserNotFoundException::new);
        String previousFileName = user.getPhotoFileName();

        String extension = validatePhoto(file);
        // Un nouveau nom renouvelle l'URL pour éviter l'affichage de l'ancienne photo en cache.
        String fileName = "user_" + userId + "_" + UUID.randomUUID() + "." + extension;
        registerPhotoCleanup(fileName, previousFileName);
        photoStorageService.storePhoto(fileName, file);

        user.setPhotoFileName(fileName);
        AppUser savedUser = appUserRepository.save(user);

        return toMyProfileResponse(savedUser);
    }

    @Transactional
    public void deletePhoto(Long userId) {
        AppUser user = appUserRepository.findByUserId(userId)
                .orElseThrow(AuthenticatedUserNotFoundException::new);
        String previousFileName = user.getPhotoFileName();

        registerPhotoCleanup(null, previousFileName);

        user.setPhotoFileName(null);
        appUserRepository.save(user);
    }

    private AppUser getAuthenticatedUser(Long userId) {
        return appUserRepository.findById(userId)
                .orElseThrow(AuthenticatedUserNotFoundException::new);
    }

    private String validatePhoto(MultipartFile file) {
        if (file.isEmpty()) {
            throw new InvalidPhotoException("Le fichier est vide.");
        }

        try (InputStream fileStream = file.getInputStream();
             ImageInputStream imageStream = new MemoryCacheImageInputStream(fileStream)) {

            // Le nom et le type déclarés par le client ne garantissent pas le format réel.
            Iterator<ImageReader> readers = ImageIO.getImageReaders(imageStream);
            if (!readers.hasNext()) {
                throw new InvalidPhotoException("Le fichier doit être une image au format JPEG ou PNG.");
            }

            ImageReader reader = readers.next();
            try {
                reader.setInput(imageStream);

                String extension = switch (reader.getFormatName().toUpperCase(Locale.ROOT)) {
                    case "JPEG" -> "jpg";
                    case "PNG" -> "png";
                    default -> throw new InvalidPhotoException("Le fichier doit être une image au format JPEG ou PNG.");
                };

                // Contrôler les dimensions avant le décodage limite la mémoire nécessaire.
                int width = reader.getWidth(0);
                int height = reader.getHeight(0);
                if (width > MAX_PHOTO_WIDTH || height > MAX_PHOTO_HEIGHT) {
                    throw new InvalidPhotoException(
                            "La largeur et la hauteur de la photo ne doivent pas dépasser 4 096 pixels.");
                }

                // Un format reconnu ne garantit pas que les pixels soient décodables.
                reader.read(0);

                return extension;
            } catch (IOException exception) {
                throw new InvalidPhotoException("La photo est illisible.", exception);
            } finally {
                reader.dispose();
            }
        } catch (IOException exception) {
            throw new UncheckedIOException("Impossible d’accéder au fichier envoyé.", exception);
        }
    }

    private void registerPhotoCleanup(String newFileName, String previousFileName) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                // Attendre le commit préserve le fichier si la modification en base échoue.
                if (previousFileName != null) {
                    photoStorageService.deletePhoto(previousFileName);
                }
            }

            @Override
            public void afterCompletion(int status) {
                if (status == STATUS_ROLLED_BACK && newFileName != null) {
                    photoStorageService.deletePhoto(newFileName);
                }
            }
        });
    }
}
