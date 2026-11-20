package fr.trill.covoit.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class PhotoUrlBuilder {

    private final String publicBaseUrl;

    public PhotoUrlBuilder(@Value("${app.public-base-url}") String publicBaseUrl) {
        this.publicBaseUrl = publicBaseUrl;
    }

    public String build(String fileName) {
        if (fileName == null) {
            return null;
        }

        return UriComponentsBuilder.fromUriString(publicBaseUrl)
                .pathSegment("photos", fileName)
                .build()
                .encode()
                .toUriString();
    }
}
