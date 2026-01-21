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
    SELECT is_verified_tenant INTO v_is_tenant
    FROM users WHERE id = p_user_id;
    
    -- Tenants book for free (except optional add-ons like tennis court lighting)
    IF v_is_tenant THEN
        RETURN 0;
    END IF;
    
    -- Get facility hourly price
    SELECT price_per_hour INTO v_price_per_hour
    FROM facilities WHERE id = p_facility_id;
    
    v_hours := EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 3600;
    
    RETURN v_price_per_hour * v_hours;
END;
$$ LANGUAGE plpgsql;

INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
SELECT 
    (CASE WHEN random() < 0.7 THEN 
        (SELECT id FROM users WHERE role = 'tenant' ORDER BY random() LIMIT 1)
    ELSE 
        (SELECT id FROM users WHERE role = 'guest' ORDER BY random() LIMIT 1)
    END) as user_id,
    
    -- Random facility
    (SELECT id FROM facilities ORDER BY random() LIMIT 1) as facility_id,
    
    -- Random date in past 7 days
    (CURRENT_DATE - INTERVAL '1 day' * FLOOR(random() * 7)::INTEGER)::DATE as booking_date,
    
    -- Random start time (06:00 to 20:00)
    (TIME '06:00:00' + INTERVAL '1 hour' * FLOOR(random() * 14)::INTEGER) as start_time,
    
    -- End time (1-3 hours after start)
    (TIME '06:00:00' + INTERVAL '1 hour' * (FLOOR(random() * 14)::INTEGER + FLOOR(random() * 3)::INTEGER + 1)) as end_time,
    
    -- Status (80% confirmed, 10% cancelled, 10% expired)
    (CASE 
        WHEN random() < 0.8 THEN 'confirmed'
        WHEN random() < 0.9 THEN 'cancelled'
        ELSE 'expired'
    END)::booking_status as status,
    
    0 as total_price
FROM generate_series(1, 200);

-- Update total_price for historical bookings
UPDATE bookings
SET total_price = calculate_booking_price(user_id, facility_id, start_time, end_time)
WHERE booking_date < CURRENT_DATE;

-- Insert TODAY's bookings (confirmed and some pending)
INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
VALUES
-- Tennis Court bookings today
(3, 1, CURRENT_DATE, '07:00:00', '08:00:00', 'confirmed', 0),  -- Tenant
(15, 1, CURRENT_DATE, '08:00:00', '09:00:00', 'confirmed', 0), -- Tenant
(23, 1, CURRENT_DATE, '16:00:00', '17:00:00', 'confirmed', 50000), -- Guest

-- Function Hall today
(5, 2, CURRENT_DATE, '10:00:00', '14:00:00', 'confirmed', 0),  -- Tenant event

-- Meeting Room A today
(7, 4, CURRENT_DATE, '09:00:00', '11:00:00', 'confirmed', 0),  -- Tenant
(25, 4, CURRENT_DATE, '14:00:00', '16:00:00', 'pending', 150000), -- Guest (waiting payment)

(10, 4, CURRENT_DATE, '17:00:00', '21:00:00', 'confirmed', 0); -- Tenant

-- Insert TOMORROW's bookings
INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
VALUES
-- Tennis Court tomorrow
(4, 1, CURRENT_DATE + 1, '06:00:00', '07:00:00', 'confirmed', 0),
(6, 1, CURRENT_DATE + 1, '18:00:00', '19:00:00', 'confirmed', 0),

-- Ballroom tomorrow (big event)
(8, 3, CURRENT_DATE + 1, '18:00:00', '23:00:00', 'confirmed', 0),

-- Meeting Rooms tomorrow
(12, 4, CURRENT_DATE + 1, '09:00:00', '10:00:00', 'confirmed', 0),
(14, 5, CURRENT_DATE + 1, '14:00:00', '15:00:00', 'confirmed', 0);

-- Insert bookings for DAY AFTER TOMORROW
INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
VALUES
-- Tennis Court
(9, 1, CURRENT_DATE + 2, '07:00:00', '08:00:00', 'pending', 0),

-- Function Hall
(11, 2, CURRENT_DATE + 2, '15:00:00', '18:00:00', 'confirmed', 0),

(13, 2, CURRENT_DATE + 2, '18:00:00', '21:00:00', 'confirmed', 0);

INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
SELECT 
    (CASE WHEN random() < 0.7 THEN 
        (SELECT id FROM users WHERE role = 'tenant' ORDER BY random() LIMIT 1)
    ELSE 
        (SELECT id FROM users WHERE role = 'guest' ORDER BY random() LIMIT 1)
    END) as user_id,
    (SELECT id FROM facilities ORDER BY random() LIMIT 1) as facility_id,
    (CURRENT_DATE + INTERVAL '1 day' * FLOOR(random() * 3 + 1)::INTEGER)::DATE as booking_date,
    (TIME '06:00:00' + INTERVAL '1 hour' * FLOOR(random() * 14)::INTEGER) as start_time,
    (TIME '06:00:00' + INTERVAL '1 hour' * (FLOOR(random() * 14)::INTEGER + FLOOR(random() * 2)::INTEGER + 1)) as end_time,
    (CASE WHEN random() < 0.7 THEN 'confirmed' ELSE 'pending' END)::booking_status as status,
    0 as total_price
FROM generate_series(1, 100)
ON CONFLICT DO NOTHING; 

UPDATE bookings
SET total_price = calculate_booking_price(user_id, facility_id, start_time, end_time)
WHERE booking_date >= CURRENT_DATE AND total_price = 0;

DROP FUNCTION calculate_booking_price(INTEGER, INTEGER, TIME, TIME);

SELECT 
    status,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE booking_date < CURRENT_DATE) as past,
    COUNT(*) FILTER (WHERE booking_date = CURRENT_DATE) as today,
    COUNT(*) FILTER (WHERE booking_date > CURRENT_DATE) as future
FROM bookings
GROUP BY status
ORDER BY status;

SELECT 
    f.name,
    COUNT(b.id) as total_bookings,
    COUNT(b.id) FILTER (WHERE b.booking_date >= CURRENT_DATE) as upcoming
FROM facilities f
LEFT JOIN bookings b ON f.id = b.facility_id
GROUP BY f.id, f.name
ORDER BY total_bookings DESC;