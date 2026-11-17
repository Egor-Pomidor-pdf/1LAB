-- Задание 2.2. Агрегация и группировка.
-- Запускать после data.sql.


\echo '===== 1. Показатели по отелям ====='

SELECT h.name AS hotel,
       h.city,
       h.stars,
       count(DISTINCT r.id) AS rooms,
       count(b.id) AS bookings,
       count(DISTINCT b.guest_id) AS guests,
       COALESCE(sum(b.total_price) FILTER (WHERE b.status IN ('paid', 'completed')), 0) AS revenue
FROM hotels h
LEFT JOIN rooms    r ON r.hotel_id = h.id
LEFT JOIN bookings b ON b.room_id  = r.id
GROUP BY h.id, h.name, h.city, h.stars
ORDER BY revenue DESC, h.name;


\echo '===== 2. Категории номеров со средним чеком выше 10 000 ====='

SELECT rt.name AS room_type,
       rt.capacity,
       rt.base_price,
       count(b.id) AS bookings,
       sum(b.total_price) AS revenue,
       round(avg(b.total_price), 2) AS avg_booking,
       min(b.total_price) AS min_booking,
       max(b.total_price) AS max_booking
FROM room_types rt
JOIN rooms    r ON r.type_id = rt.id
JOIN bookings b ON b.room_id = r.id
WHERE b.status IN ('paid', 'completed')
GROUP BY rt.id, rt.name, rt.capacity, rt.base_price
HAVING count(b.id) >= 3
   AND avg(b.total_price) > 10000
ORDER BY revenue DESC;


\echo '===== 3. Сравнение сегментов отелей по месяцам заезда ====='

SELECT to_char(b.check_in, 'YYYY-MM') AS month,
       CASE WHEN h.stars >= 4 THEN 'премиум 4-5*' ELSE 'эконом 1-3*' END AS segment,
       count(*) AS bookings,
       count(*) FILTER (WHERE b.status = 'cancelled') AS cancelled,
       COALESCE(sum(b.total_price) FILTER (WHERE b.status IN ('paid', 'completed')), 0) AS revenue,
       round(avg(b.total_price), 2) AS avg_booking,
       min(b.total_price) AS min_booking,
       max(b.total_price) AS max_booking
FROM bookings b
JOIN rooms  r ON r.id = b.room_id
JOIN hotels h ON h.id = r.hotel_id
GROUP BY month, segment
ORDER BY month, segment;
