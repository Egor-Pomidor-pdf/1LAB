-- Часть 4. Комплексный аналитический отчёт.
-- Загрузка номерного фонда, выручка и собираемость оплат по отелям
-- за второе полугодие 2026 года.
-- Запускать после data.sql.

WITH period AS (
    SELECT DATE '2026-07-01' AS period_start,
           DATE '2026-12-31' AS period_end
),
booking_src AS (
    SELECT b.id,
           b.status,
           b.total_price,
           b.check_in,
           b.check_out,
           r.hotel_id,
           r.type_id
    FROM bookings b
    JOIN rooms r ON r.id = b.room_id
    CROSS JOIN period p
    WHERE b.check_in BETWEEN p.period_start AND p.period_end
),
booking_metrics AS (
    SELECT s.id,
           s.hotel_id,
           s.type_id,
           s.status,
           s.total_price,
           s.check_out - s.check_in AS nights,
           COALESCE((SELECT sum(pm.amount)
                     FROM payments pm
                     WHERE pm.booking_id = s.id), 0) AS paid_amount
    FROM booking_src s
),
hotel_totals AS (
    SELECT m.hotel_id,
           count(*) AS bookings_total,
           count(*) FILTER (WHERE m.status = 'cancelled') AS bookings_cancelled,
           COALESCE(sum(m.nights) FILTER (WHERE m.status <> 'cancelled'), 0) AS nights_sold,
           COALESCE(sum(m.total_price) FILTER (WHERE m.status IN ('paid', 'completed')), 0) AS revenue_charged,
           COALESCE(sum(m.paid_amount) FILTER (WHERE m.status <> 'cancelled'), 0) AS revenue_received,
           round(avg(m.total_price), 2) AS avg_booking,
           max(m.total_price) AS max_booking
    FROM booking_metrics m
    GROUP BY m.hotel_id
),
hotel_capacity AS (
    SELECT r.hotel_id,
           count(*) AS rooms_total,
           count(*) * (p.period_end - p.period_start + 1) AS room_nights_available
    FROM rooms r
    CROSS JOIN period p
    GROUP BY r.hotel_id, p.period_start, p.period_end
),
type_revenue AS (
    SELECT m.hotel_id,
           m.type_id,
           COALESCE(sum(m.total_price) FILTER (WHERE m.status IN ('paid', 'completed')), 0) AS revenue
    FROM booking_metrics m
    GROUP BY m.hotel_id, m.type_id
),
top_type AS (
    SELECT tr.hotel_id, tr.type_id, tr.revenue
    FROM type_revenue tr
    WHERE tr.revenue = (SELECT max(x.revenue)
                        FROM type_revenue x
                        WHERE x.hotel_id = tr.hotel_id)
      AND tr.revenue > 0
)
SELECT h.name AS hotel,
       h.city,
       h.stars,
       COALESCE(c.rooms_total, 0) AS rooms,
       COALESCE(t.bookings_total, 0) AS bookings,
       COALESCE(t.bookings_cancelled, 0) AS cancelled,
       round(100.0 * t.bookings_cancelled / NULLIF(t.bookings_total, 0), 1) AS cancel_rate_pct,
       COALESCE(t.nights_sold, 0) AS nights_sold,
       COALESCE(c.room_nights_available, 0) AS room_nights_available,
       round(100.0 * t.nights_sold / NULLIF(c.room_nights_available, 0), 1) AS occupancy_pct,
       COALESCE(t.revenue_charged, 0) AS revenue_charged,
       COALESCE(t.revenue_received, 0) AS revenue_received,
       COALESCE(t.revenue_charged, 0) - COALESCE(t.revenue_received, 0) AS debt,
       round(100.0 * t.revenue_received / NULLIF(t.revenue_charged, 0), 1) AS collection_pct,
       COALESCE(t.avg_booking, 0) AS avg_booking,
       COALESCE(t.max_booking, 0) AS max_booking,
       rt.name AS top_room_type
FROM hotels h
LEFT JOIN hotel_capacity c  ON c.hotel_id = h.id
LEFT JOIN hotel_totals   t  ON t.hotel_id = h.id
LEFT JOIN top_type       tt ON tt.hotel_id = h.id
LEFT JOIN room_types     rt ON rt.id = tt.type_id
ORDER BY revenue_charged DESC, h.name;
