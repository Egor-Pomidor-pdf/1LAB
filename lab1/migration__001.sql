BEGIN;

CREATE TABLE booking_rooms (
booking_id   INTEGER NOT NULL REFERENCES bookings (id) ON DELETE CASCADE,
room_id      INTEGER NOT NULL REFERENCES rooms (id)    ON DELETE RESTRICT,
check_in     DATE NOT NULL,
check_out    DATE NOT NULL,
guests_count SMALLINT NOT NULL CHECK (guests_count BETWEEN 1 AND 6),
price        NUMERIC(10,2) NOT NULL CHECK (price > 0),
CONSTRAINT booking_rooms_pkey PRIMARY KEY (booking_id, room_id),
CONSTRAINT booking_rooms_dates_check CHECK (check_out > check_in)
);

INSERT INTO booking_rooms (booking_id, room_id, check_in, check_out, guests_count, price)
SELECT id, room_id, check_in, check_out, guests_count, total_price
FROM bookings;

ALTER TABLE bookings
    DROP COLUMN room_id,
    DROP COLUMN check_in,
    DROP COLUMN check_out,
    DROP COLUMN guests_count,
    DROP COLUMN total_price;

COMMIT;



-- CREATE TABLE bookings (
--     id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--     guest_id   INTEGER NOT NULL REFERENCES guests (id) ON DELETE RESTRICT,
--     status     VARCHAR(100) NOT NULL DEFAULT 'new'
--                CHECK (status IN ('new', 'paid', 'cancelled', 'completed')),
--     created_at TIMESTAMPTZ NOT NULL DEFAULT now()


-- CREATE TABLE bookings (
--     id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--     guest_id     INTEGER NOT NULL REFERENCES guests (id) ON DELETE RESTRICT,
--     room_id      INTEGER NOT NULL REFERENCES rooms (id) ON DELETE RESTRICT,
--     check_in     DATE NOT NULL,
--     check_out    DATE NOT NULL,
--     guests_count SMALLINT NOT NULL CHECK (guests_count BETWEEN 1 AND 6),
--     status       VARCHAR(100) NOT NULL DEFAULT 'new'
--                  CHECK (status IN ('new', 'paid', 'cancelled', 'completed')),
--     total_price  NUMERIC(10,2) NOT NULL CHECK (total_price > 0),
--     created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
--     CONSTRAINT bookings_dates_check CHECK (check_out > check_in)
-- );