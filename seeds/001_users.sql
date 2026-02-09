TRUNCATE users RESTART IDENTITY CASCADE;

INSERT INTO users (full_name, phone_number, role, is_verified_tenant, unit_number) VALUES
('Super Admin', '+6281234567890', 'super_admin', TRUE, '1701'),
('Admin User', '+6281234567891', 'admin', TRUE, '1702');

INSERT INTO users (full_name, phone_number, role, is_verified_tenant, unit_number) VALUES
('Budi Santoso', '+6281234567892', 'tenant', TRUE, '1703'),
('Siti Nurhaliza', '+6281234567893', 'tenant', TRUE, '1704'),
('Ahmad Wijaya', '+6281234567894', 'tenant', TRUE, '1705'),
('Dewi Lestari', '+6281234567895', 'tenant', TRUE, '1706'),
('Eko Prasetyo', '+6281234567896', 'tenant', TRUE, '1707'),
('Fitri Handayani', '+6281234567897', 'tenant', TRUE, '1708'),
('Gita Savitri', '+6281234567898', 'tenant', TRUE, '1709'),
('Hadi Susanto', '+6281234567899', 'tenant', TRUE, '1710'),
('Indah Permata', '+6281234567800', 'tenant', TRUE, '1711'),
('Joko Widodo', '+6281234567801', 'tenant', TRUE, '1712'),
('Kartika Putri', '+6281234567802', 'tenant', TRUE, '1713'),
('Lukman Hakim', '+6281234567803', 'tenant', TRUE, '1714'),
('Maya Sari', '+6281234567804', 'tenant', TRUE, '1715'),
('Nanda Arsyad', '+6281234567805', 'tenant', TRUE, '1716'),
('Olivia Tan', '+6281234567806', 'tenant', TRUE, '1717'),
('Prima Rahman', '+6281234567807', 'tenant', TRUE, '1718'),
('Qori Sandioriva', '+6281234567808', 'tenant', TRUE, '1719'),
('Rudi Hartono', '+6281234567809', 'tenant', TRUE, '1720'),
('Sinta Dewi', '+6281234567810', 'tenant', TRUE, '1721'),
('Tono Wijaya', '+6281234567811', 'tenant', TRUE, '1722');

INSERT INTO users (full_name, phone_number, role, is_verified_tenant, unit_number) VALUES
('Guest User 1', '+6281234567812', 'guest', FALSE, NULL),
('Guest User 2', '+6281234567813', 'guest', FALSE, NULL),
('Guest User 3', '+6281234567814', 'guest', FALSE, NULL),
('Guest User 4', '+6281234567815', 'guest', FALSE, NULL),
('Guest User 5', '+6281234567816', 'guest', FALSE, NULL),
('Guest User 6', '+6281234567817', 'guest', FALSE, NULL),
('Guest User 7', '+6281234567818', 'guest', FALSE, NULL),
('Guest User 8', '+6281234567819', 'guest', FALSE, NULL),
('Guest User 9', '+6281234567820', 'guest', FALSE, NULL),
('Guest User 10', '+6281234567821', 'guest', FALSE, NULL);

INSERT INTO users (full_name, phone_number, role, is_verified_tenant, unit_number)
SELECT 
    'Tenant ' || gs.n,
    '+628' || LPAD((1234567822 + gs.n)::TEXT, 10, '0'),
    'tenant',
    TRUE,
    (1700 + gs.n)::TEXT
FROM generate_series(1, 70) AS gs(n);

INSERT INTO users (full_name, phone_number, role, is_verified_tenant, unit_number)
SELECT 
    'Guest ' || gs.n,
    '+628' || LPAD((1234567922 + gs.n)::TEXT, 10, '0'),
    'guest',
    FALSE,
    NULL
FROM generate_series(11, 40) AS gs(n);

SELECT 
    role,
    is_verified_tenant,
    COUNT(*) as count
FROM users
GROUP BY role, is_verified_tenant
ORDER BY role;