#!/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to ensure Docker is installed
setup_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        echo "Docker installed successfully. Please log out and back in for group changes to take effect."
    else
        echo "Docker is already installed."
    fi
}
# Function to build Salt Master container
build_salt_master() {
    echo "Building Salt Master container..."
    docker pull ghcr.io/cdalvaro/docker-salt-master:3007.1_3
}

# Function to run Salt Master container
run_salt_master() {
    echo "Running Salt Master container..."
    docker run --name salt_master --detach \
        --publish 4505:4505 --publish 4506:4506 \
        --env 'SALT_LOG_LEVEL=info' \
        --volume $(pwd)/roots/:/home/salt/data/srv/ \
        --volume $(pwd)/keys/:/home/salt/data/keys/ \
        --volume $(pwd)/logs/:/home/salt/data/logs/ \
        ghcr.io/cdalvaro/docker-salt-master:3007.1_3
}

# Function to setup Salt Minion locally
# Add this new function
accept_minion_key() {
    echo "Accepting Minion key..."
    sleep 10  # Give some time for the key to be registered
    docker exec salt_master salt-key -A -y
}

# Modify the setup_salt_minion function to include key acceptance
setup_salt_minion() {
    echo "Setting up Salt Minion..."

    # Stop the salt-minion service if it's running
    sudo systemctl stop salt-minion || true

    # Remove existing Salt installation and configuration
    sudo apt-get remove -y salt-minion || true
    sudo apt-get purge -y salt-minion || true
    sudo apt-get autoremove -y
    sudo rm -rf /etc/salt /var/cache/salt /var/log/salt /var/run/salt || true

    # Update package lists
    sudo apt-get update

    # Install Salt minion
    sudo apt-get install -y salt-minion

    echo "Configuring Salt Minion to connect to localhost..."
    sudo sed -i 's/#master: salt/master: localhost/' /etc/salt/minion

    echo "Restarting Salt Minion service..."
    sudo systemctl restart salt-minion

    echo "Waiting for Salt Minion to start..."
    sleep 10
    sudo systemctl status salt-minion
    
    # Accept the minion key
    accept_minion_key
}

test_salt_connection() {
    echo "Testing Salt connection..."
    for i in {1..6}; do
        echo "Attempt $i: Waiting 10 seconds for the minion to connect..."
        sleep 10
        echo "Attempting to ping minion from Salt Master..."
        if docker exec salt_master salt '*' test.ping; then
            echo "Connection successful!"
            return 0
        fi
        echo "Connection attempt $i failed. Retrying..."
    done
    echo "All connection attempts failed. Running diagnostics..."
    diagnose_salt_connection
    return 1
}

# Function to clone a git repository
clone_git_repo() {
    if [ -z "$1" ]; then
        echo "Please provide a git repository URL."
        return 1
    fi
    echo "Cloning git repository: $1"
    docker run --rm -v /opt:/opt alpine/git clone "$1" /opt/$(basename "$1" .git)
}

# Function to run Salt highstate
run_highstate() {
    echo "Running Salt highstate..."
    docker exec salt_master salt '*' state.highstate
}

# Function to diagnose Salt connection issues
diagnose_salt_connection() {
    echo "Diagnosing Salt connection..."
    
    echo "1. Checking Salt Master container status:"
    docker ps -a | grep salt_master
    
    echo "2. Checking Salt Master logs:"
    docker logs salt_master --tail 50
    
    echo "3. Checking Salt Minion status:"
    sudo systemctl status salt-minion
    
    echo "4. Checking Salt Minion logs:"
    sudo tail -n 50 /var/log/salt/minion
    
    echo "5. Checking Salt Minion configuration:"
    grep master /etc/salt/minion
    
    echo "6. Checking network connectivity:"
    nc -zv localhost 4505
    nc -zv localhost 4506
}
cleanup() {
    echo "Cleaning up Docker containers, networks, and volumes..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    docker network prune -f
    docker volume prune -f
}

adjust_permissions() {
    local user=$(whoami)
    local opt_dir="/opt"
    local exclude_dirs=("$@")
    local exclude_args=""

    # Build exclude arguments for find command
    for dir in "${exclude_dirs[@]}"; do
        exclude_args="$exclude_args -not -path '$opt_dir/$dir*'"
    done

    # Change ownership of files and directories in /opt
    # shellcheck disable=SC2086
    sudo find "$opt_dir" $exclude_args -exec chown "$user:$user" {} +

    echo "Permissions adjusted for $user in $opt_dir (excluding ${exclude_dirs[*]:-none})"
}

# Main execution
case "$1" in
    docker)
        setup_docker
        ;;
    build)
        build_salt_master
        ;;
    run)
        run_salt_master
        ;;
    minion)
        setup_salt_minion
        ;;
    test)
        test_salt_connection
        ;;
    clone)
        clone_git_repo "$2"
        ;;
    highstate)
        run_highstate
        ;;
    diagnose)
        diagnose_salt_connection
        ;;
    permissions)
        shift
        adjust_permissions "$@"
        ;;
    clean)
        cleanup
        ;;
    all)
        setup_docker
        build_salt_master
        run_salt_master
        setup_salt_minion
        test_salt_connection
        run_highstate
        ;;
    *)
        echo "Usage: $0 {docker|build|run|minion|test|clone|highstate|all}"
        exit 1
        ;;
esac

exit 0
