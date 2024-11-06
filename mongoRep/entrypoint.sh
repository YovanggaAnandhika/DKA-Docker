#!/bin/bash
set -e

# File penanda untuk inisialisasi MongoDB
INITIALIZED_FLAG="/var/dka.init"

# Function to check if MongoDB is ready
check_mongo_ready() {
    until mongosh --eval "print('MongoDB is ready')" >/dev/null 2>&1; do
        echo "Waiting for MongoDB to start..."
        sleep 1
    done
    echo "MongoDB is up and running."
}

# Function to run initialization scripts
run_init_scripts() {
    if [ -d /docker-entrypoint-initdb.d ]; then
        for file in /docker-entrypoint-initdb.d/*.js; do
            if [ -f "$file" ]; then
                echo "Running $file"
                mongosh < "$file" > /dev/null 2>&1
            fi
        done
    fi
}

# Function to initialize MongoDB for the first time
initialize_mongo() {
    echo "First time MongoDB start, using default config..."
    mongod --config /etc/mongod.default.conf &
    MONGOD_PID=$!
    check_mongo_ready
    run_init_scripts
    echo "Stopping MongoDB temporarily..."
    kill $MONGOD_PID
    # Create a flag file to mark MongoDB as initialized
    touch $INITIALIZED_FLAG
}

# Function to start MongoDB with regular config
start_mongo() {
    echo "MongoDB already initialized, using default config..."
    mongod --config /etc/mongod.conf &
    MONGOD_PID=$!
    check_mongo_ready
}

# Main script logic
echo "Starting MongoDB initialization script..."
if [ ! -f $INITIALIZED_FLAG ]; then
    # First run: initialize MongoDB
    initialize_mongo
    # Restart MongoDB with regular config after initialization
    mongod --config /etc/mongod.conf &
    MONGOD_PID=$!
    check_mongo_ready
else
    # Not the first run: start MongoDB normally
    start_mongo
fi

# Keep the container running by tailing the MongoDB log
tail -f /var/log/mongodb/mongod.log
