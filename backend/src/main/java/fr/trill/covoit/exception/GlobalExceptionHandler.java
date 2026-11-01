package fr.trill.covoit.exception;

import fr.trill.covoit.dto.ErrorResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import tools.jackson.databind.exc.InvalidNullException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleInvalidRequestBody(HttpMessageNotReadableException ex) {
        // Un null refusé par Jackson est présenté comme une erreur de validation du champ.
        if (ex.getMostSpecificCause() instanceof InvalidNullException invalidNull
                && invalidNull.getPropertyName() != null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse.builder()
                            .code("VALIDATION_ERROR")
                            .message("Certaines informations sont invalides.")
                            .fieldErrors(Map.of(invalidNull.getPropertyName().getSimpleName(),
                                    "Ce champ ne peut pas être null."))
                            .build());
        }

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("INVALID_REQUEST_BODY", "Le corps de la requête est absent ou invalide."));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException ex) {
        List<FieldError> errors = ex.getBindingResult().getFieldErrors();
        Map<String, String> fieldErrors = new HashMap<>();

        // On conserve d'abord les erreurs des informations obligatoires.
        for (FieldError error : errors) {
            String code = error.getCode();

            boolean requiredValueError = "NotNull".equals(code)
                    || "NotBlank".equals(code)
                    || "NotEmpty".equals(code);

            if (requiredValueError) {
                fieldErrors.putIfAbsent(
                        error.getField(),
                        error.getDefaultMessage()
                );
            }
        }

        // On complète les champs qui n'ont pas encore de message.
        for (FieldError error : errors) {
            fieldErrors.putIfAbsent(
                    error.getField(),
                    error.getDefaultMessage()
            );
        }

        ErrorResponse errorResponse = ErrorResponse.builder()
                .code("VALIDATION_ERROR")
                .message("Certaines informations sont invalides.")
                .fieldErrors(fieldErrors)
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }
}
