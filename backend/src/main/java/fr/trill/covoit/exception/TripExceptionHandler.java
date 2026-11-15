package fr.trill.covoit.exception;

import fr.trill.covoit.dto.ErrorResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class TripExceptionHandler {

    @ExceptionHandler(TripCapacityExceededException.class)
    public ResponseEntity<ErrorResponse> handleCapacityExceeded(TripCapacityExceededException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ErrorResponse("TRIP_CAPACITY_EXCEEDED", ex.getMessage()));
    }
}
