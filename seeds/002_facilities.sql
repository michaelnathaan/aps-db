TRUNCATE facilities RESTART IDENTITY CASCADE;

INSERT INTO facilities (name, description, price_per_hour, open_time, close_time, is_active) VALUES
(
    'Tennis Court',
    'Outdoor tennis court with professional-grade surface. Court lighting available for additional fee (request at reception).',
    50000,
    '06:00:00',
    '22:00:00',
    TRUE
),
(
    'Function Hall',
    'Spacious function hall suitable for events, meetings, and celebrations. Capacity: 100 people. Includes basic audio system.',
    150000,
    '08:00:00',
    '23:00:00',
    TRUE
),
(
    'Ballroom',
    'Elegant ballroom for weddings, conferences, and large gatherings. Capacity: 200 people. Includes stage, projector, and premium sound system.',
    300000,
    '08:00:00',
    '23:00:00',
    TRUE
),
(
    'Meeting Room A',
    'Professional meeting room with whiteboard, projector, and video conferencing equipment. Capacity: 12 people.',
    75000,
    '07:00:00',
    '22:00:00',
    TRUE
),
(
    'Meeting Room B',
    'Smaller meeting room ideal for team discussions. Includes TV screen and whiteboard. Capacity: 8 people.',
    50000,
    '07:00:00',
    '22:00:00',
    TRUE
),
(
    'Swimming Pool',
    'Olympic-size swimming pool. Includes changing rooms and shower facilities. Lifeguard on duty during operating hours.',
    0,
    '06:00:00',
    '20:00:00',
    TRUE
),
(
    'Gym',
    'Fully equipped fitness center with cardio machines, free weights, and strength training equipment.',
    0,
    '05:00:00',
    '23:00:00',
    TRUE
),

-- Verify seed data
SELECT 
    id,
    name,
    price_per_hour,
    TO_CHAR(open_time, 'HH24:MI') as opens,
    TO_CHAR(close_time, 'HH24:MI') as closes,
    is_active
FROM facilities
ORDER BY id;

-- Count summary
SELECT 
    COUNT(*) as total_facilities,
    COUNT(*) FILTER (WHERE price_per_hour > 0) as paid_facilities,
    COUNT(*) FILTER (WHERE price_per_hour = 0) as free_facilities
FROM facilities;