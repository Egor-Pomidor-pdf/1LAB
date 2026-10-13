-- Проверка ограничений целостности (запускать после schema.sql и data.sql).
-- Все операции до раздела «Демонстрация ON DELETE» должны завершиться ошибкой.

\echo 'NOT NULL: отель без города'
INSERT INTO hotels (name, city, address, stars, phone)
VALUES ('Безымянный', NULL, 'ул. Ленина, 1', 3, '+7-000-000-00-00');

\echo 'CHECK: количество звёзд вне диапазона 1..5'
INSERT INTO hotels (name, city, address, stars, phone)
VALUES ('Семь Звёзд', 'Казань', 'ул. Баумана, 1', 7, '+7-843-555-07-07');

\echo 'составной UNIQUE: второе «Приморье» в Сочи'
INSERT INTO hotels (name, city, address, stars, phone)
VALUES ('Приморье', 'Сочи', 'ул. Другая, 5', 3, '+7-862-555-09-09');

\echo 'GENERATED ALWAYS: id вручную'
INSERT INTO hotels (id, name, city, address, stars, phone)
VALUES (100, 'Ручной Айди', 'Омск', 'ул. Ленина, 2', 3, '+7-381-555-05-05');

\echo 'UNIQUE: email уже занят'
INSERT INTO guests (first_name, last_name, passport_no, email, phone, birth_date)
VALUES ('Игорь', 'Новиков', '4599 999999', 'ivanov@example.com', '+7-900-666-66-66', '1995-02-02');

\echo 'UNIQUE: паспорт уже занят'
INSERT INTO guests (first_name, last_name, passport_no, email, phone, birth_date)
VALUES ('Егор', 'Егоров', '4510 123456', 'egorov@example.com', '+7-900-777-77-77', '1993-08-08');

\echo 'CHECK: формат email'
INSERT INTO guests (first_name, last_name, passport_no, email, phone, birth_date)
VALUES ('Иван', 'Ошибкин', '4598 888888', 'not-an-email', '+7-900-888-88-88', '1993-08-08');

\echo 'CHECK: дата рождения в будущем'
INSERT INTO guests (first_name, last_name, passport_no, email, phone, birth_date)
VALUES ('Ещё', 'Неродился', '4597 777777', 'future@example.com', '+7-900-999-99-99', '2030-01-01');

\echo 'составной UNIQUE: второй номер «101» в отеле 1'
INSERT INTO rooms (hotel_id, type_id, room_number, floor)
VALUES (1, 2, '101', 1);

\echo 'CHECK: этаж вне диапазона 1..50'
INSERT INTO rooms (hotel_id, type_id, room_number, floor)
VALUES (1, 2, '999', 80);

\echo 'FK: номер в несуществующем отеле'
INSERT INTO rooms (hotel_id, type_id, room_number, floor)
VALUES (999, 1, '101', 1);

\echo 'составной CHECK: выезд не позже заезда'
INSERT INTO bookings (guest_id, room_id, check_in, check_out, guests_count, total_price)
VALUES (1, 5, '2026-11-10', '2026-11-10', 2, 7000.00);

\echo 'CHECK: недопустимый статус брони'
UPDATE bookings SET status = 'postponed' WHERE id = 1;

\echo 'CHECK: ноль проживающих'
UPDATE bookings SET guests_count = 0 WHERE id = 1;

\echo 'FK: бронь на несуществующий номер'
INSERT INTO bookings (guest_id, room_id, check_in, check_out, guests_count, total_price)
VALUES (1, 999, '2026-11-01', '2026-11-03', 1, 5000.00);

\echo 'CHECK: отрицательная сумма платежа'
UPDATE payments SET amount = -500.00 WHERE id = 1;

\echo 'CHECK: недопустимый способ оплаты'
INSERT INTO payments (booking_id, amount, method)
VALUES (1, 1000.00, 'bitcoin');

\echo 'RESTRICT: у гостя есть брони'
DELETE FROM guests WHERE id = 1;

\echo 'RESTRICT: номер забронирован'
DELETE FROM rooms WHERE id = 2;

\echo 'RESTRICT: категория используется номерами'
DELETE FROM room_types WHERE id = 1;


\echo 'Демонстрация ON DELETE (изменения откатываются)'
BEGIN;

\echo 'CASCADE: отель без броней удаляется вместе со своими номерами'
SELECT count(*) AS rooms_before FROM rooms WHERE hotel_id = 4;
DELETE FROM hotels WHERE id = 4;
SELECT count(*) AS rooms_after FROM rooms WHERE hotel_id = 4;

\echo 'CASCADE: удаление брони удаляет её платежи'
SELECT count(*) AS payments_before FROM payments WHERE booking_id = 1;
DELETE FROM bookings WHERE id = 1;
SELECT count(*) AS payments_after FROM payments WHERE booking_id = 1;

ROLLBACK;

\echo 'После отката данные на месте'
SELECT 'hotels' AS table_name, count(*) FROM hotels
UNION ALL SELECT 'room_types', count(*) FROM room_types
UNION ALL SELECT 'rooms',      count(*) FROM rooms
UNION ALL SELECT 'guests',     count(*) FROM guests
UNION ALL SELECT 'bookings',   count(*) FROM bookings
UNION ALL SELECT 'payments',   count(*) FROM payments;
