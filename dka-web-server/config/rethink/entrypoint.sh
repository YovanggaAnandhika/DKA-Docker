#!/bin/bash
set -e

# Start RethinkDB in the background
rethinkdb --bind all &

# Wait for RethinkDB to start
sleep 10

# Set up the admin user and password if provided
if [ -n "$RETHINKDB_ADMIN_USER" ] && [ -n "$RETHINKDB_ADMIN_PASSWORD" ]; then
    # Insert admin user with password
    # shellcheck disable=SC1073
    r.db('rethinkdb').table('users').insert({
      id: process.env.RETHINKDB_ADMIN_USER,
      password: process.env.RETHINKDB_ADMIN_PASSWORD
    })
fi

# Bring RethinkDB back to the foreground
wait
