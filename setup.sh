#!/bin/bash

set -e

# Function to start Salt Master container
start_salt_master() {
    echo "Starting Salt Master container..."
    docker compose up -d salt-master
    echo "Waiting for Salt Master to start..."
    sleep 30
}

# Function to start Salt Minion container
start_salt_minion() {
    echo "Starting Salt Minion container..."
    docker compose up -d salt-minion
    echo "Waiting for Salt Minion to start..."
    sleep 10
}

# Function to accept Minion key
accept_minion_key() {
    echo "Accepting Minion key..."
    docker compose exec salt-master salt-key -A -y
}

# Function to test Salt connection
test_salt_connection() {
    echo "Testing Salt connection..."
    for i in {1..6}; do
        echo "Attempt $i: Waiting 10 seconds for the minion to connect..."
        sleep 10
        echo "Attempting to ping minion from Salt Master..."
        if docker compose exec salt-master salt '*' test.ping; then
            echo "Connection successful!"
            return 0
        fi
        echo "Connection attempt $i failed. Retrying..."
    done
    echo "All connection attempts failed. Running diagnostics..."
    diagnose_salt_connection
    return 1
}

# Function to diagnose Salt connection issues
diagnose_salt_connection() {
    echo "Diagnosing Salt connection..."
    
    echo "1. Checking Salt Master container status:"
    docker compose ps salt-master
    
    echo "2. Checking Salt Master logs:"
    docker compose logs --tail 50 salt-master
    
    echo "3. Checking Salt Minion container status:"
    docker compose ps salt-minion
    
    echo "4. Checking Salt Minion logs:"
    docker compose logs --tail 50 salt-minion
    
    echo "5. Checking network connectivity:"
    docker compose exec salt-master nc -zv salt-minion 4505
    docker compose exec salt-master nc -zv salt-minion 4506
}

# Main execution
echo "Setting up Salt environment..."
start_salt_master
start_salt_minion
accept_minion_key
if test_salt_connection; then
    echo "Salt setup completed successfully!"
else
    echo "Salt setup failed. Please check the diagnostics above."
    exit 1
fi
