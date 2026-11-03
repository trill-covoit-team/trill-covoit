package fr.trill.covoit.exception;

import fr.trill.covoit.dto.ErrorResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleInvalidRequestBody() {
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
