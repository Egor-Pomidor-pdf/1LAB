-- Задание 2.1. Многотабличные запросы.
-- Запускать после data.sql.


\echo '===== 1. Подробная информация о бронированиях ====='

SELECT b.id AS booking,
       g.last_name || ' ' || g.first_name AS guest,
       h.name AS hotel,
       h.city,
       r.room_number,
       rt.name AS room_type,
       b.check_in,
       b.check_out,
       b.check_out - b.check_in AS nights,
       b.guests_count,
       b.status,
       b.total_price
FROM bookings b
JOIN guests     g  ON g.id  = b.guest_id
JOIN rooms      r  ON r.id  = b.room_id
JOIN hotels     h  ON h.id  = r.hotel_id
JOIN room_types rt ON rt.id = r.type_id
ORDER BY b.check_in, b.id;


\echo '===== 2. Номера, которые ни разу не бронировали ====='

SELECT h.name AS hotel,
       h.city,
       r.room_number,
       r.floor,
       rt.name AS room_type,
       rt.base_price
FROM rooms r
JOIN hotels     h  ON h.id  = r.hotel_id
JOIN room_types rt ON rt.id = r.type_id
LEFT JOIN bookings b ON b.room_id = r.id
WHERE b.id IS NULL
ORDER BY h.name, r.room_number;


\echo '===== 3. Дорогие брони в отелях 4-5* на вместительные номера ====='

SELECT h.name AS hotel,
       h.stars,
       rt.name AS room_type,
       rt.capacity,
       g.last_name || ' ' || g.first_name AS guest,
       b.check_in,
       b.guests_count,
       b.status,
       b.total_price
FROM bookings b
JOIN rooms      r  ON r.id  = b.room_id
JOIN hotels     h  ON h.id  = r.hotel_id
JOIN room_types rt ON rt.id = r.type_id
JOIN guests     g  ON g.id  = b.guest_id
WHERE h.stars >= 4
  AND rt.capacity >= 3
  AND b.status IN ('paid', 'completed')
  AND b.total_price > 20000
  AND b.check_in >= '2026-08-01'
ORDER BY b.total_price DESC, h.name;
