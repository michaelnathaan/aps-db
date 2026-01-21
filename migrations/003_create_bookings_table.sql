CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'expired', 'cancelled');

CREATE TABLE IF NOT EXISTS bookings (
    id                      SERIAL PRIMARY KEY,
    user_id                 INTEGER NOT NULL,
    facility_id             INTEGER NOT NULL,
    booking_date            DATE NOT NULL,
    start_time              TIME NOT NULL,
    end_time                TIME NOT NULL,
    status                  booking_status DEFAULT 'pending' NOT NULL,
    total_price             INTEGER DEFAULT 0 NOT NULL,
    created_at              TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at              TIMESTAMP DEFAULT NOW() NOT NULL,
    
    CONSTRAINT fk_bookings_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_bookings_facility 
        FOREIGN KEY (facility_id) 
        REFERENCES facilities(id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    CONSTRAINT valid_time_range CHECK (start_time < end_time),
    CONSTRAINT price_non_negative CHECK (total_price >= 0),
    CONSTRAINT future_or_today_booking CHECK (booking_date >= CURRENT_DATE),
    CONSTRAINT max_3_days_advance CHECK (
        booking_date <= CURRENT_DATE + INTERVAL '3 days'
    )
);

CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_facility_id ON bookings(facility_id);
CREATE INDEX idx_bookings_booking_date ON bookings(booking_date);
CREATE INDEX idx_bookings_status ON bookings(status);

CREATE UNIQUE INDEX idx_bookings_conflict_prevention 
    ON bookings(facility_id, booking_date, start_time, end_time)
    WHERE status NOT IN ('cancelled', 'expired');

CREATE INDEX idx_bookings_user_date 
    ON bookings(user_id, booking_date DESC, start_time DESC);

CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE bookings IS 'Facility booking reservations';
COMMENT ON COLUMN bookings.status IS 'Booking status: pending (awaiting payment/verification), confirmed (paid/verified), expired (payment timeout), cancelled (user/admin cancelled)';
COMMENT ON COLUMN bookings.total_price IS 'Total booking price in IDR (calculated as price_per_hour * hours)';
COMMENT ON INDEX idx_bookings_conflict_prevention IS 'Prevents double-booking of same facility at same time (excludes cancelled/expired bookings)';