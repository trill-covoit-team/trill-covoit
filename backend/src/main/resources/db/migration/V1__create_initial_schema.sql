CREATE TABLE app_user
(
    user_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    email_verified BOOLEAN      NOT NULL DEFAULT FALSE,
    first_name     VARCHAR(100),
    last_name      VARCHAR(100),
    photo_url      TEXT,
    bio            TEXT
);

CREATE TABLE vehicle
(
    vehicle_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    brand              VARCHAR(100) NOT NULL,
    model              VARCHAR(100) NOT NULL,
    passenger_capacity INT          NOT NULL CHECK (passenger_capacity > 0),
    user_id            BIGINT       NOT NULL,
    FOREIGN KEY (user_id) REFERENCES app_user (user_id)
);

CREATE TABLE trip
(
    trip_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    departure_address  TEXT        NOT NULL,
    arrival_address    TEXT        NOT NULL,
    departure_datetime TIMESTAMP   NOT NULL,
    offered_seats      INT         NOT NULL CHECK (offered_seats > 0),
    status             VARCHAR(20) NOT NULL CHECK (status IN ('PUBLISHED', 'CANCELLED', 'COMPLETED')),
    vehicle_id         BIGINT      NOT NULL,
    driver_id          BIGINT      NOT NULL,
    FOREIGN KEY (vehicle_id) REFERENCES vehicle (vehicle_id),
    FOREIGN KEY (driver_id) REFERENCES app_user (user_id)
);
