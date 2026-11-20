package fr.trill.covoit.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

@Configuration
public class PhotoWebConfig implements WebMvcConfigurer {

    private final String photoLocation;

    public PhotoWebConfig(@Value("${app.photo.storage-directory}") String directory) {
        String location = Path.of(directory).toAbsolutePath().normalize().toUri().toString();
        // Le / final est nécessaire même si le dossier n'existe pas encore au démarrage.
        this.photoLocation = location.endsWith("/") ? location : location + "/";
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/photos/**")
                .addResourceLocations(photoLocation);
    }
}
