set -e

echo "WARNING: This will destroy all data in the database!"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-apsadmin}
POSTGRES_DB=${POSTGRES_DB:-apartment_booking}

echo ""
echo "Dropping database: $POSTGRES_DB"

PGPASSWORD=$POSTGRES_PASSWORD psql \
    -h $POSTGRES_HOST \
    -p $POSTGRES_PORT \
    -U $POSTGRES_USER \
    -d postgres \
    -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"

echo "Creating database: $POSTGRES_DB"

PGPASSWORD=$POSTGRES_PASSWORD psql \
    -h $POSTGRES_HOST \
    -p $POSTGRES_PORT \
    -U $POSTGRES_USER \
    -d postgres \
    -c "CREATE DATABASE $POSTGRES_DB;"

echo ""
echo "Database reset complete!"
echo ""