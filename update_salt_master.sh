#!/bin/bash

REPO_DIR="/app/docker-salt-master"
REMOTE_URL="https://github.com/cdalvaro/docker-salt-master.git"

get_latest_release() {
  curl --silent "https://api.github.com/repos/cdalvaro/docker-salt-master/releases/latest" | 
    grep '"tag_name":' |                                            
    sed -E 's/.*"([^"]+)".*/\1/'
}

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository..."
    LATEST_TAG=$(get_latest_release)
    git clone -b $LATEST_TAG $REMOTE_URL $REPO_DIR
    rm -rf $REPO_DIR/.git
else
    echo "Repository exists. Checking for updates..."
    
    CURRENT_VERSION=$(cat $REPO_DIR/VERSION)
    LATEST_VERSION=$(get_latest_release)
    
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo "New version available: $LATEST_VERSION"
        echo "Current version: $CURRENT_VERSION"
        echo "Updating to latest version..."
        rm -rf $REPO_DIR
        git clone -b $LATEST_VERSION $REMOTE_URL $REPO_DIR
        rm -rf $REPO_DIR/.git
    else
        echo "Already up to date."
    fi
fi

echo "Done."
