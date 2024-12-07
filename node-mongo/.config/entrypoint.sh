#!/bin/sh

# File penanda untuk inisialisasi MongoDB
INITIALIZED_FLAG="/var/dka.init"
# Set default value for DKA_MONGO_ROOT_USER if not provided
export DKA_DB_MONGO_USERNAME="${DKA_DB_MONGO_USERNAME:-developer}"
export DKA_DB_MONGO_PASSWORD="${DKA_DB_MONGO_PASSWORD:-Cyberhack2010}"
export DKA_DB_MONGO_CLUSTER_IS_PRIMARY="${DKA_DB_MONGO_CLUSTER_IS_PRIMARY:-false}"
export DKA_DB_MONGO_REPLICA_NAME="${DKA_DB_MONGO_REPLICA_NAME:-rs0}"

# Generate SSH host keys if they don't exist
ssh-keygen -A

chmod 600 /etc/keyfile

# Check if the root password has been previously generated
if [ -f /root/.password_set ]; then
    echo "Root password is already set. Not generating a new password."
else
    # Check if the environment variable for the root password is set
    if [ -z "$DKA_SSH_ROOT_PASSWORD" ]; then
        # Generate a random password for the root user
        ROOT_PASSWORD=$(openssl rand -base64 20)
        echo "================================================================="
        echo "Generated root password: $ROOT_PASSWORD"
        echo "================================================================="
    else
        ROOT_PASSWORD="$DKA_SSH_ROOT_PASSWORD"
        echo "Using provided root password: $ROOT_PASSWORD"
    fi
    # Set the root password
    echo "root:$ROOT_PASSWORD" | chpasswd

    # Create a file to indicate that the password has been set
    touch /root/.password_set
fi

# Start the SSH server
/usr/sbin/sshd -D &

# Function to check if MongoDB is ready
check_mongo_ready() {
    echo "Waiting for MongoDB to start..."
    until mongosh --eval "print('MongoDB is ready')" >/dev/null 2>&1; do
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
    MONGO_PID=$!
    check_mongo_ready
    run_init_scripts
    echo "Stopping MongoDB temporarily..."
    kill $MONGO_PID
    wait $MONGO_PID
    # Create a flag file to mark MongoDB as initialized
    touch $INITIALIZED_FLAG
}

# Function to start MongoDB with regular config
start_mongo() {
    echo "MongoDB already initialized, using default config..."
    mongod --config /etc/mongod.conf --replSet $DKA_DB_MONGO_REPLICA_NAME &
    MONGO_PID=$!
    check_mongo_ready
}

# Main script logic
echo "Starting MongoDB initialization script..."
if [ ! -f $INITIALIZED_FLAG ]; then
    # First run: initialize MongoDB
    initialize_mongo
    # Restart MongoDB with regular config after initialization
    mongod --config /etc/mongod.conf --replSet $DKA_DB_MONGO_REPLICA_NAME &
    MONGO_PID=$!
    check_mongo_ready
else
    # Not the first run: start MongoDB normally
    start_mongo
fi

# Start MongoDB or perform other tasks
exec "$@"  # This will pass the remaining arguments to the CMD command

