#!/bin/bash

# Set build arguments
export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
export VCS_REF=$(cat docker-salt-master/VERSION)

# Build and start the containers
docker compose up --build -d salt-master salt-minion

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Accept the minion key
echo "Accepting minion key..."
docker compose exec salt-master salt-key -A -y

# Test the connection
echo "Testing connection..."
docker compose exec salt-master salt '*' test.ping

# If the test fails, show logs
if [ $? -ne 0 ]; then
    echo "Connection test failed. Showing logs:"
    docker compose logs
fi
