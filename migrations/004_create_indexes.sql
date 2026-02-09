CREATE INDEX idx_bookings_active 
    ON bookings(facility_id, booking_date, start_time) 
    WHERE status IN ('pending', 'confirmed');

CREATE INDEX idx_bookings_facility_date_time 
    ON bookings(facility_id, booking_date, start_time, end_time)
    WHERE status IN ('pending', 'confirmed');

CREATE INDEX idx_bookings_expired_cleanup 
    ON bookings(created_at)
    WHERE status = 'pending';

CREATE INDEX idx_bookings_user_date_count
    ON bookings(user_id, booking_date)
    WHERE status IN ('pending', 'confirmed');

ANALYZE users;
ANALYZE facilities;
ANALYZE bookings;

COMMENT ON INDEX idx_bookings_active IS 'Optimizes slot availability queries for active bookings';
COMMENT ON INDEX idx_bookings_facility_date_time IS 'Optimizes conflict detection and availability checks';
COMMENT ON INDEX idx_bookings_expired_cleanup IS 'Optimizes background job that expires unpaid bookings';
COMMENT ON INDEX idx_bookings_user_date_count IS 'Optimizes "max 4 bookings per day" validation';