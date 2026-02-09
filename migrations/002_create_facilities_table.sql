CREATE TABLE IF NOT EXISTS facilities (
    id                      SERIAL PRIMARY KEY,
    name                    VARCHAR(100) UNIQUE NOT NULL,
    description             TEXT,
    price_per_hour          INTEGER DEFAULT 0 NOT NULL,
    open_time               TIME DEFAULT '06:00:00' NOT NULL,
    close_time              TIME DEFAULT '23:59:59' NOT NULL,
    is_active               BOOLEAN DEFAULT TRUE NOT NULL,
    created_at              TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at              TIMESTAMP DEFAULT NOW() NOT NULL,
    
    CONSTRAINT price_non_negative CHECK (price_per_hour >= 0),
    CONSTRAINT valid_operating_hours CHECK (open_time < close_time)
);

CREATE INDEX idx_facilities_is_active ON facilities(is_active);
CREATE INDEX idx_facilities_name ON facilities(name);

CREATE TRIGGER update_facilities_updated_at
    BEFORE UPDATE ON facilities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
    
COMMENT ON TABLE facilities IS 'Bookable facilities in the apartment complex';
COMMENT ON COLUMN facilities.price_per_hour IS 'Hourly booking price in IDR (0 for free facilities)';
COMMENT ON COLUMN facilities.open_time IS 'Facility operating hours start time';
COMMENT ON COLUMN facilities.close_time IS 'Facility operating hours end time';
COMMENT ON COLUMN facilities.is_active IS 'Whether facility is currently available for booking';