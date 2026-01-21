# 🗄️ APS Database

PostgreSQL database schema for the Apartment Booking System (APS) - supporting GraphQL vs REST performance comparison research.

## 📋 Overview

This repository contains:
- Database schema (migrations)
- Seed data for testing
- Management scripts
- Documentation

**Research Context:** This database is shared by both REST and GraphQL backend implementations to ensure fair performance comparison.

## 🏗️ Schema

### Tables

| Table | Purpose | Rows (seeded) |
|-------|---------|---------------|
| `users` | User accounts with role-based access | ~132 |
| `facilities` | Bookable facilities | 8 |
| `bookings` | Facility reservations | ~300+ |

### Key Features

- ✅ Enforced foreign key constraints
- ✅ Check constraints for business rules
- ✅ Optimized indexes for both REST and GraphQL
- ✅ Automatic timestamp updates
- ✅ Conflict prevention via unique partial index

See [docs/schema.md](docs/schema.md) for detailed schema documentation.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- PostgreSQL client tools (optional, for scripts)

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your settings (optional, defaults work fine)
nano .env
```

### 2. Start Database

```bash
# Start PostgreSQL with Docker Compose
docker-compose up -d

# Check status
docker-compose ps
```

The database will automatically run migrations on first startup.

### 3. Seed Data

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run seed scripts
./scripts/seed-db.sh
```

### 4. Verify

```bash
# Connect to database
docker-compose exec postgres psql -U apsadmin -d apartment_booking

# Check tables
\dt

# Check data
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM facilities;
SELECT COUNT(*) FROM bookings;

# Exit
\q
```

## 🛠️ Management Scripts

### Initialize Database

```bash
./scripts/init-db.sh
```

Runs all migration files in order. Safe to run multiple times (idempotent).

### Seed Test Data

```bash
./scripts/seed-db.sh
```

Populates database with realistic test data:
- 132 users (90 tenants, 40 guests, 2 admins)
- 8 facilities (tennis court, function hall, etc.)
- 300+ bookings (past, present, future)

### Reset Database

```bash
./scripts/reset-db.sh
```

⚠️ **DESTRUCTIVE:** Drops and recreates the database. Requires confirmation.

## 📊 Accessing the Database

### Option 1: Docker Exec

```bash
docker-compose exec postgres psql -U apsadmin -d apartment_booking
```

### Option 2: pgAdmin (Web UI)

1. Open http://localhost:5050
2. Login with:
   - Email: `admin@aps.local`
   - Password: `admin123`
3. Add server:
   - Host: `postgres`
   - Port: `5432`
   - Database: `apartment_booking`
   - Username: `apsadmin`
   - Password: (from `.env`)

### Option 3: External Tools

Use any PostgreSQL client with:

```
Host: localhost
Port: 5432
Database: apartment_booking
Username: apsadmin
Password: (from .env)
```

## 🔍 Key Queries

### Check User Distribution

```sql
SELECT role, is_verified_tenant, COUNT(*)
FROM users
GROUP BY role, is_verified_tenant;
```

### Check Booking Status Distribution

```sql
SELECT status, COUNT(*)
FROM bookings
GROUP BY status;
```

### Check Today's Bookings

```sql
SELECT 
    b.id,
    u.full_name,
    f.name as facility,
    b.start_time,
    b.end_time,
    b.status
FROM bookings b
JOIN users u ON b.user_id = u.id
JOIN facilities f ON b.facility_id = f.id
WHERE b.booking_date = CURRENT_DATE
ORDER BY b.start_time;
```

### Find Booking Conflicts (should be 0)

```sql
SELECT 
    b1.facility_id,
    b1.booking_date,
    b1.start_time,
    b1.end_time,
    b2.start_time,
    b2.end_time
FROM bookings b1
JOIN bookings b2 ON 
    b1.facility_id = b2.facility_id AND
    b1.booking_date = b2.booking_date AND
    b1.id != b2.id
WHERE 
    b1.status NOT IN ('cancelled', 'expired') AND
    b2.status NOT IN ('cancelled', 'expired') AND
    (b1.start_time, b1.end_time) OVERLAPS (b2.start_time, b2.end_time);
```

## 📁 Directory Structure

```
aps-db/
├── migrations/           # Schema definition (run in order)
│   ├── 001_create_users_table.sql
│   ├── 002_create_facilities_table.sql
│   ├── 003_create_bookings_table.sql
│   └── 004_create_indexes.sql
├── seeds/               # Test data
│   ├── 001_users.sql
│   ├── 002_facilities.sql
│   └── 003_bookings.sql
├── scripts/             # Management scripts
│   ├── init-db.sh
│   ├── seed-db.sh
│   └── reset-db.sh
├── docs/                # Documentation
│   ├── schema.md
│   └── ERD.md
├── docker-compose.yml   # Docker setup
├── .env.example         # Environment template
└── README.md           # This file
```

## 🧪 For Researchers

### Data Characteristics

- **Realistic volume:** 300+ bookings, 132 users
- **Distribution:** 70% tenants, 30% guests (reflects real usage)
- **Temporal spread:** Historical bookings (past 7 days) + future bookings (next 3 days)
- **Status mix:** 80% confirmed, 10% cancelled, 10% expired/pending

### Performance Considerations

- All indexes are designed to be **fair** for both REST and GraphQL
- No bias toward nested queries or flat queries
- Conflict detection uses partial unique index (excludes cancelled/expired)
- Composite indexes support common query patterns

### Reproducibility

To recreate the exact database state:

```bash
./scripts/reset-db.sh   # Start fresh
./scripts/init-db.sh    # Run migrations
./scripts/seed-db.sh    # Load test data
```

## 🐛 Troubleshooting

### Database won't start

```bash
# Check logs
docker-compose logs postgres

# Restart
docker-compose restart postgres
```

### Can't connect

```bash
# Verify container is running
docker-compose ps

# Check port availability
lsof -i :5432
```

### Migrations fail

```bash
# Check current database state
docker-compose exec postgres psql -U apsadmin -d apartment_booking -c '\dt'

# Reset and retry
./scripts/reset-db.sh
./scripts/init-db.sh
```

## 📚 Related Repositories

- `aps-backend` - REST and GraphQL API implementations
- `aps-frontend` - Web application UI

## 📄 License

MIT License - See main project repository

---

**For questions or issues, please open an issue in the main project repository.**