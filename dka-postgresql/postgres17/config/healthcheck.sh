#!/bin/sh

DB_HOST=${DKA_DB_HOST:-127.0.0.1}
DB_PORT=${DKA_DB_PORT:-5432}
DB_USER=${DKA_DB_USERNAME:-postgres}
DB_NAME=${DKA_DB_NAME:-postgres}

pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
exit $?
