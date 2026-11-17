-- Часть 3. Подзапросы и поиск нетривиальных ситуаций.
-- Запускать после data.sql.


\echo '===== 1. Брони дороже средней брони по своей категории номера ====='

SELECT h.name AS hotel,
       r.room_number,
       rt.name AS room_type,
       b.id AS booking,
       b.check_in,
       b.total_price,
       a.avg_price AS avg_by_room_type,
       b.total_price - a.avg_price AS difference
FROM bookings b
JOIN rooms      r  ON r.id  = b.room_id
JOIN hotels     h  ON h.id  = r.hotel_id
JOIN room_types rt ON rt.id = r.type_id
JOIN (
    SELECT r.type_id, round(avg(b.total_price), 2) AS avg_price
    FROM bookings b
    JOIN rooms r ON r.id = b.room_id
    GROUP BY r.type_id
) a ON a.type_id = r.type_id
WHERE b.total_price > a.avg_price
ORDER BY difference DESC;


\echo '===== 2. EXISTS: гости с отменённой бронью, по которой прошла оплата ====='

SELECT g.id,
       g.last_name || ' ' || g.first_name AS guest,
       g.email,
       g.phone
FROM guests g
WHERE EXISTS (
    SELECT 1
    FROM bookings b
    JOIN payments p ON p.booking_id = b.id
    WHERE b.guest_id = g.id
      AND b.status = 'cancelled'
)
ORDER BY g.id;


\echo '===== 3. NOT EXISTS: оплаченные брони без единого платежа ====='

SELECT b.id AS booking,
       g.last_name || ' ' || g.first_name AS guest,
       h.name AS hotel,
       r.room_number,
       b.check_in,
       b.status,
       b.total_price
FROM bookings b
JOIN guests g ON g.id = b.guest_id
JOIN rooms  r ON r.id = b.room_id
JOIN hotels h ON h.id = r.hotel_id
WHERE b.status IN ('paid', 'completed')
  AND NOT EXISTS (
      SELECT 1
      FROM payments p
      WHERE p.booking_id = b.id
  )
ORDER BY b.check_in;


\echo '===== 4. Коррелированный подзапрос: гости с задолженностью ====='

SELECT g.id,
       g.last_name || ' ' || g.first_name AS guest,
       (SELECT count(*)
        FROM bookings b
        WHERE b.guest_id = g.id) AS bookings_total,
       (SELECT COALESCE(sum(b.total_price), 0)
        FROM bookings b
        WHERE b.guest_id = g.id
          AND b.status IN ('paid', 'completed')) AS charged,
       (SELECT COALESCE(sum(p.amount), 0)
        FROM payments p
        JOIN bookings b ON b.id = p.booking_id
        WHERE b.guest_id = g.id) AS paid,
       (SELECT COALESCE(sum(b.total_price), 0)
        FROM bookings b
        WHERE b.guest_id = g.id
          AND b.status IN ('paid', 'completed'))
     - (SELECT COALESCE(sum(p.amount), 0)
        FROM payments p
        JOIN bookings b ON b.id = p.booking_id
        WHERE b.guest_id = g.id) AS debt
FROM guests g
WHERE (SELECT COALESCE(sum(p.amount), 0)
       FROM payments p
       JOIN bookings b ON b.id = p.booking_id
       WHERE b.guest_id = g.id)
    < (SELECT COALESCE(sum(b.total_price), 0)
       FROM bookings b
       WHERE b.guest_id = g.id
         AND b.status IN ('paid', 'completed'))
ORDER BY debt DESC;
