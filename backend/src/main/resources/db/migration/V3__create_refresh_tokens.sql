CREATE TABLE auth_session
(
    session_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT      NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    FOREIGN KEY (user_id) REFERENCES app_user (user_id)
);

CREATE TABLE refresh_token
(
    token_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    session_id BIGINT      NOT NULL,
    used_at    TIMESTAMPTZ,
    FOREIGN KEY (session_id) REFERENCES auth_session (session_id)
);
