set -e

echo "Seeding APS Database..."

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-apsadmin}
POSTGRES_DB=${POSTGRES_DB:-apartment_booking}

echo "Database: $POSTGRES_DB"
echo ""

run_sql() {
    local file=$1
    echo "   Seeding: $(basename $file)"
    PGPASSWORD=$POSTGRES_PASSWORD psql \
        -h $POSTGRES_HOST \
        -p $POSTGRES_PORT \
        -U $POSTGRES_USER \
        -d $POSTGRES_DB \
        -f "$file" \
        -v ON_ERROR_STOP=1
}

echo "Running seed files..."
for seed in seeds/*.sql; do
    run_sql "$seed"
done

echo "Database seeded successfully!"
echo "Data summary:"
PGPASSWORD=$POSTGRES_PASSWORD psql \
    -h $POSTGRES_HOST \
    -p $POSTGRES_PORT \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB \
    -c "SELECT 'Users' as table_name, COUNT(*) as count FROM users
        UNION ALL
        SELECT 'Facilities', COUNT(*) FROM facilities
        UNION ALL
        SELECT 'Bookings', COUNT(*) FROM bookings;"