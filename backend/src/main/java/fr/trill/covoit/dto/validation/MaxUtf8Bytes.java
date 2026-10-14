package fr.trill.covoit.dto.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = MaxUtf8BytesValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface MaxUtf8Bytes {

    String message() default "Le mot de passe est trop long.";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    int max() default 72;
}
