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

-- 2. Generate 10,000 Past Bookings
INSERT INTO bookings (user_id, facility_id, booking_date, start_time, end_time, status, total_price)
SELECT 
    user_id, 
    facility_id, 
    past_date, 
    start_t, 
    start_t + duration AS end_t, 
    status, 
    0 -- Temporary 0, will update in next step
FROM (
    SELECT 
        -- Randomly pick a user (70% chance of being a tenant)
        (CASE WHEN random() < 0.7 THEN 
            (SELECT id FROM users WHERE role = 'tenant' ORDER BY random() LIMIT 1)
         ELSE 
            (SELECT id FROM users WHERE role = 'guest' ORDER BY random() LIMIT 1)
         END) AS user_id,

        -- Randomly pick a facility
        (SELECT id FROM facilities ORDER BY random() LIMIT 1) AS facility_id,

        -- Dates strictly BETWEEN 1 year ago and 1 day ago
        (CURRENT_DATE - (FLOOR(random() * 364 + 1)::int * INTERVAL '1 day'))::DATE AS past_date,

        -- Random start time between 06:00 and 18:00
        (TIME '06:00:00' + FLOOR(random() * 12)::int * INTERVAL '1 hour') AS start_t,

        -- Random duration between 1 and 4 hours
        ((FLOOR(random() * 4)::int + 1) * INTERVAL '1 hour') AS duration,

        -- Past status distribution
        (CASE 
            WHEN random() < 0.85 THEN 'confirmed'
            WHEN random() < 0.95 THEN 'cancelled'
            ELSE 'expired'
         END)::booking_status AS status
    FROM generate_series(1, 13000)
) t
WHERE start_t + duration <= TIME '23:00:00'
ON CONFLICT DO NOTHING;

-- 3. Bulk calculate prices for the new data
UPDATE bookings 
SET total_price = calculate_booking_price(user_id, facility_id, start_time, end_time)
WHERE total_price = 0;

-- 4. Cleanup
DROP FUNCTION calculate_booking_price(INTEGER, INTEGER, TIME, TIME);

-- 5. Final Verification
SELECT 
    status,
    COUNT(*) as total_rows,
    MIN(booking_date) as oldest_record,
    MAX(booking_date) as newest_record
FROM bookings 
GROUP BY status;