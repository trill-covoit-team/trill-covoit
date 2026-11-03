package fr.trill.covoit.exception;

import fr.trill.covoit.dto.ErrorResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class VehicleExceptionHandler {

    @ExceptionHandler(EmptyVehicleUpdateException.class)
    public ResponseEntity<ErrorResponse> handleEmptyUpdate(EmptyVehicleUpdateException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("VALIDATION_ERROR", ex.getMessage()));
    }

    @ExceptionHandler(VehicleNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleVehicleNotFound(VehicleNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse("VEHICLE_NOT_FOUND", ex.getMessage()));
    }

    @ExceptionHandler(VehicleCapacityConflictException.class)
    public ResponseEntity<ErrorResponse> handleCapacityConflict(VehicleCapacityConflictException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ErrorResponse("VEHICLE_CAPACITY_CONFLICT", ex.getMessage()));
    }

    @ExceptionHandler(VehicleInUseException.class)
    public ResponseEntity<ErrorResponse> handleVehicleInUse(VehicleInUseException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ErrorResponse("VEHICLE_IN_USE", ex.getMessage()));
    }
}
