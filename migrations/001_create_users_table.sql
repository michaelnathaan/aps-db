CREATE TYPE user_role AS ENUM ('guest', 'tenant', 'admin', 'super_admin');

CREATE TABLE IF NOT EXISTS users (
    id                      SERIAL PRIMARY KEY,
    full_name               VARCHAR(255) NOT NULL,
    phone_number            VARCHAR(20) UNIQUE NOT NULL,
    role                    user_role DEFAULT 'guest' NOT NULL,
    is_verified_tenant      BOOLEAN DEFAULT FALSE NOT NULL,
    unit_number             VARCHAR(10),
    created_at              TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at              TIMESTAMP DEFAULT NOW() NOT NULL,
    
    CONSTRAINT phone_number_format CHECK (phone_number ~ '^\+?[0-9]{10,15}$'),
    CONSTRAINT unit_number_required_for_tenant CHECK (
        (is_verified_tenant = TRUE AND unit_number IS NOT NULL) OR
        (is_verified_tenant = FALSE)
    )
);

CREATE INDEX idx_users_phone_number ON users(phone_number);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_verified_tenant ON users(is_verified_tenant);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE users IS 'Stores user accounts with role-based access control';
COMMENT ON COLUMN users.role IS 'User role: guest (default), tenant (verified resident), admin, super_admin';
COMMENT ON COLUMN users.is_verified_tenant IS 'Whether user is verified as apartment tenant (affects booking pricing)';
COMMENT ON COLUMN users.unit_number IS 'Apartment unit number (required for verified tenants)';