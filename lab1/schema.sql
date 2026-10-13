-- Структура БД системы бронирования гостиниц.
-- Скрипт можно запускать повторно: таблицы пересоздаются.

DROP TABLE IF EXISTS hotels, room_types, rooms, guests, bookings, payments CASCADE;


CREATE TABLE hotels (
    id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    city    VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    stars   SMALLINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
    phone   VARCHAR(20) NOT NULL,
    CONSTRAINT hotels_name_city_unique UNIQUE (name, city)
);


CREATE TABLE room_types (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,
    capacity   SMALLINT NOT NULL CHECK (capacity BETWEEN 1 AND 6),
    base_price NUMERIC(10,2) NOT NULL CHECK (base_price > 0)
);


CREATE TABLE rooms (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hotel_id    INTEGER NOT NULL REFERENCES hotels (id) ON DELETE CASCADE,
    type_id     INTEGER NOT NULL REFERENCES room_types (id) ON DELETE RESTRICT,
    room_number VARCHAR(10) NOT NULL,
    floor       SMALLINT NOT NULL CHECK (floor BETWEEN 1 AND 50),
    CONSTRAINT rooms_number_unique UNIQUE (hotel_id, room_number)
);


CREATE TABLE guests (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    passport_no VARCHAR(20) NOT NULL UNIQUE,
    email       VARCHAR(100) NOT NULL UNIQUE CHECK (email LIKE '%_@_%._%'),
    phone       VARCHAR(20) NOT NULL,
    birth_date  DATE NOT NULL CHECK (birth_date < CURRENT_DATE)
);


CREATE TABLE bookings (
    id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    guest_id     INTEGER NOT NULL REFERENCES guests (id) ON DELETE RESTRICT,
    room_id      INTEGER NOT NULL REFERENCES rooms (id) ON DELETE RESTRICT,
    check_in     DATE NOT NULL,
    check_out    DATE NOT NULL,
    guests_count SMALLINT NOT NULL CHECK (guests_count BETWEEN 1 AND 6),
    status       VARCHAR(100) NOT NULL DEFAULT 'new'
                 CHECK (status IN ('new', 'paid', 'cancelled', 'completed')),
    total_price  NUMERIC(10,2) NOT NULL CHECK (total_price > 0),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT bookings_dates_check CHECK (check_out > check_in)
);


CREATE TABLE payments (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings (id) ON DELETE CASCADE,
    amount     NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    paid_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    method     VARCHAR(100) NOT NULL CHECK (method IN ('card', 'cash', 'transfer'))
);
