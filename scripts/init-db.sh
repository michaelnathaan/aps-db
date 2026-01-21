set -e

echo "Initializing APS Database..."

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo ".env file not found. Using defaults."
fi

POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-apsadmin}
POSTGRES_DB=${POSTGRES_DB:-apartment_booking}

echo "Database: $POSTGRES_DB"
echo "Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "User: $POSTGRES_USER"
echo ""

run_sql() {
    local file=$1
    echo "   Running: $(basename $file)"
    PGPASSWORD=$POSTGRES_PASSWORD psql \
        -h $POSTGRES_HOST \
        -p $POSTGRES_PORT \
        -U $POSTGRES_USER \
        -d $POSTGRES_DB \
        -f "$file" \
        -v ON_ERROR_STOP=1 \
        --quiet
}

echo "Running migrations..."
for migration in migrations/*.sql; do
    run_sql "$migration"
done

echo "Database initialized successfully!"
echo "To verify, run:"
echo "   psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -c '\dt'"