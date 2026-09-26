#!/bin/sh

DB_HOST=${DKA_DB_HOST:-127.0.0.1}
DB_PORT=${DKA_DB_PORT:-5432}
DB_USER=${DKA_DB_USERNAME:-postgres}
DB_NAME=${DKA_DB_NAME:-postgres}

# 1. Cek kesehatan PostgreSQL utama
pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
PG_STATUS=$?

if [ "$PG_STATUS" -ne 0 ]; then
    exit $PG_STATUS
fi

# 2. Cek kesehatan PgBouncer (jika diaktifkan)
if [ "$DKA_PGBOUNCER_ENABLE" = "true" ]; then
    PGBOUNCER_PORT=${DKA_PGBOUNCER_PORT:-6432}
    echo "Checking PgBouncer on port $PGBOUNCER_PORT..."
    pg_isready -h "$DB_HOST" -p "$PGBOUNCER_PORT" -U "$DB_USER" -d "$DB_NAME"
    exit $?
fi

exit 0
