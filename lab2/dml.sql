-- Задание 1.2. Операции изменения данных.
-- Запускать после data.sql. Пункты 1-4 фиксируются, пункт 5 откатывается.
-- Чтобы вернуть базу к исходному набору, повторно запустить data.sql.


\echo '===== 1. Новая сущность и связанные с ней записи ====='

BEGIN;

INSERT INTO hotels (name, city, address, stars, phone)
VALUES ('Янтарь', 'Калининград', 'ул. Портовая, 9', 4, '+7-401-555-07-07');

INSERT INTO rooms (hotel_id, type_id, room_number, floor)
SELECT h.id, rt.id, v.room_number, v.floor
FROM hotels h
CROSS JOIN (VALUES ('201', 2, 'Стандарт'), ('202', 2, 'Стандарт'), ('301', 3, 'Люкс'))
     AS v (room_number, floor, type_name)
JOIN room_types rt ON rt.name = v.type_name
WHERE h.name = 'Янтарь' AND h.city = 'Калининград';

INSERT INTO guests (first_name, last_name, passport_no, email, phone, birth_date)
VALUES ('Артём', 'Гусев', '4530 121314', 'gusev@example.com', '+7-902-444-44-45', '1995-06-21');

INSERT INTO bookings (guest_id, room_id, check_in, check_out, guests_count, status, total_price)
SELECT g.id, r.id, '2026-11-24', '2026-11-27', 2, 'paid', 13500.00
FROM guests g
JOIN rooms  r  ON r.room_number = '201'
JOIN hotels h  ON h.id = r.hotel_id AND h.name = 'Янтарь' AND h.city = 'Калининград'
WHERE g.passport_no = '4530 121314';

INSERT INTO payments (booking_id, amount, paid_at, method)
SELECT b.id, 13500.00, '2026-10-24 12:00+03', 'card'
FROM bookings b
JOIN guests g ON g.id = b.guest_id
WHERE g.passport_no = '4530 121314';

SELECT h.name AS hotel, count(DISTINCT r.id) AS rooms, count(DISTINCT b.id) AS bookings,
       count(p.id) AS payments
FROM hotels h
LEFT JOIN rooms    r ON r.hotel_id = h.id
LEFT JOIN bookings b ON b.room_id = r.id
LEFT JOIN payments p ON p.booking_id = b.id
WHERE h.name = 'Янтарь'
GROUP BY h.name;

COMMIT;


\echo '===== 2. Изменение состояния операции ====='

BEGIN;

UPDATE bookings
SET status = 'paid'
WHERE id = 32;

INSERT INTO payments (booking_id, amount, paid_at, method)
VALUES (32, 24000.00, '2026-10-25 09:30+03', 'transfer');

SELECT b.id, b.status, b.total_price, sum(p.amount) AS paid
FROM bookings b
JOIN payments p ON p.booking_id = b.id
WHERE b.id = 32
GROUP BY b.id, b.status, b.total_price;

COMMIT;


\echo '===== 3. Массовое изменение: просроченные неоплаченные брони отменяются ====='

BEGIN;

SELECT id, check_in, status
FROM bookings
WHERE status = 'new'
  AND check_in < CURRENT_DATE
  AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.booking_id = bookings.id)
ORDER BY id;

UPDATE bookings
SET status = 'cancelled'
WHERE status = 'new'
  AND check_in < CURRENT_DATE
  AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.booking_id = bookings.id);

SELECT status, count(*) AS bookings
FROM bookings
GROUP BY status
ORDER BY status;

COMMIT;


\echo '===== 4. Удаление с учётом ограничений целостности ====='

BEGIN;

\echo 'отель 6 «Транзит»: нет ни номеров, ни броней — удаляется'
DELETE FROM hotels WHERE id = 6;

\echo 'номер 25: броней нет, RESTRICT не препятствует'
DELETE FROM rooms
WHERE id = 25
  AND NOT EXISTS (SELECT 1 FROM bookings b WHERE b.room_id = rooms.id);

COMMIT;

\echo 'гость 1: брони есть, ON DELETE RESTRICT отклоняет удаление'
DELETE FROM guests WHERE id = 1;


\echo '===== 5. Отмена изменений через ROLLBACK ====='

BEGIN;

SELECT sum(total_price) AS total_before FROM bookings;

UPDATE bookings
SET total_price = total_price * 1.10
WHERE status IN ('new', 'paid');

SELECT sum(total_price) AS total_after_update FROM bookings;

ROLLBACK;

SELECT sum(total_price) AS total_after_rollback FROM bookings;
