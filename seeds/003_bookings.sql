TRUNCATE bookings RESTART IDENTITY CASCADE;

CREATE OR REPLACE FUNCTION calculate_booking_price(
    p_user_id INTEGER,
    p_facility_id INTEGER,
    p_start_time TIME,
    p_end_time TIME
) RETURNS INTEGER AS $$
DECLARE
    v_is_tenant BOOLEAN;
    v_price_per_hour INTEGER;
    v_hours NUMERIC;
BEGIN
    SELECT is_verified_tenant INTO v_is_tenant FROM users WHERE id = p_user_id;
    IF v_is_tenant THEN RETURN 0; END IF;
    
    SELECT price_per_hour INTO v_price_per_hour FROM facilities WHERE id = p_facility_id;
    
    v_hours := EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 3600;
    RETURN v_price_per_hour * v_hours;
END;
$$ LANGUAGE plpgsql;

-- ==================== EXPLICIT BOOKINGS FIRST ====================
INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
VALUES
    (3,  1, CURRENT_DATE, '07:00:00', '08:00:00', 'confirmed', 0),
    (15, 1, CURRENT_DATE, '08:00:00', '09:00:00', 'confirmed', 0),
    (23, 1, CURRENT_DATE, '16:00:00', '17:00:00', 'confirmed', 50000),
    (5,  2, CURRENT_DATE, '10:00:00', '14:00:00', 'confirmed', 0),
    (7,  4, CURRENT_DATE, '09:00:00', '11:00:00', 'confirmed', 0),
    (25, 4, CURRENT_DATE, '14:00:00', '16:00:00', 'pending', 150000),
    (10, 4, CURRENT_DATE, '17:00:00', '21:00:00', 'confirmed', 0),

    (4,  1, CURRENT_DATE + 1, '06:00:00', '07:00:00', 'confirmed', 0),
    (6,  1, CURRENT_DATE + 1, '18:00:00', '19:00:00', 'confirmed', 0),
    (8,  3, CURRENT_DATE + 1, '18:00:00', '23:00:00', 'confirmed', 0),
    (12, 4, CURRENT_DATE + 1, '09:00:00', '10:00:00', 'confirmed', 0),
    (14, 5, CURRENT_DATE + 1, '14:00:00', '15:00:00', 'confirmed', 0),

    (9,  1, CURRENT_DATE + 2, '07:00:00', '08:00:00', 'pending', 0),
    (11, 2, CURRENT_DATE + 2, '15:00:00', '18:00:00', 'confirmed', 0),
    (13, 2, CURRENT_DATE + 2, '18:00:00', '21:00:00', 'confirmed', 0)
ON CONFLICT DO NOTHING;

-- ==================== RANDOM BOOKINGS 1 ====================
INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
SELECT 
    user_id, facility_id, booking_date, start_time, 
    start_time + duration AS end_time, 
    status, 0
FROM (
    SELECT 
        (CASE WHEN random() < 0.7 THEN 
            (SELECT id FROM users WHERE role = 'tenant' ORDER BY random() LIMIT 1)
         ELSE 
            (SELECT id FROM users WHERE role = 'guest' ORDER BY random() LIMIT 1)
         END) AS user_id,

        (SELECT id FROM facilities ORDER BY random() LIMIT 1) AS facility_id,

        (CURRENT_DATE + FLOOR(random() * 3)::int * INTERVAL '1 day')::DATE AS booking_date,

        (TIME '06:00:00' + FLOOR(random() * 13)::int * INTERVAL '1 hour') AS start_time,

        ((FLOOR(random() * 4)::int + 1) * INTERVAL '1 hour') AS duration,

        (CASE 
            WHEN random() < 0.8 THEN 'confirmed'
            WHEN random() < 0.9 THEN 'cancelled'
            ELSE 'expired'
         END)::booking_status AS status
    FROM generate_series(1, 200)
) t
WHERE start_time + duration <= TIME '23:00:00'
  AND start_time < start_time + duration
ON CONFLICT DO NOTHING;

-- ==================== RANDOM BOOKINGS 2 (Future) ====================
INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
SELECT 
    user_id, facility_id, booking_date, start_time, 
    start_time + duration AS end_time, 
    status, 0
FROM (
    SELECT 
        (CASE WHEN random() < 0.7 THEN 
            (SELECT id FROM users WHERE role = 'tenant' ORDER BY random() LIMIT 1)
         ELSE 
            (SELECT id FROM users WHERE role = 'guest' ORDER BY random() LIMIT 1)
         END) AS user_id,

        (SELECT id FROM facilities ORDER BY random() LIMIT 1) AS facility_id,

        (CURRENT_DATE + (FLOOR(random() * 3 + 1)::int) * INTERVAL '1 day')::DATE AS booking_date,

        (TIME '06:00:00' + FLOOR(random() * 13)::int * INTERVAL '1 hour') AS start_time,

        ((FLOOR(random() * 4)::int + 1) * INTERVAL '1 hour') AS duration,

        (CASE WHEN random() < 0.7 THEN 'confirmed' ELSE 'pending' END)::booking_status AS status
    FROM generate_series(1, 100)
) t
WHERE start_time + duration <= TIME '23:00:00'
ON CONFLICT DO NOTHING;

-- Calculate prices
UPDATE bookings 
SET total_price = calculate_booking_price(user_id, facility_id, start_time, end_time)
WHERE total_price = 0;

DROP FUNCTION calculate_booking_price(INTEGER, INTEGER, TIME, TIME);

-- Summary
SELECT 
    status,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE booking_date < CURRENT_DATE) as past,
    COUNT(*) FILTER (WHERE booking_date = CURRENT_DATE) as today,
    COUNT(*) FILTER (WHERE booking_date > CURRENT_DATE) as future
FROM bookings 
GROUP BY status 
ORDER BY status;