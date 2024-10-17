# Salt-Docker Project Management System Setup Guide

This guide explains how to use the `setup.sh` script and the purpose of each feature.

## Overview

The `setup.sh` script is designed to automate the setup and management of the Salt-Docker Project Management System. It provides various options to handle different aspects of the setup process.

## Usage

```bash
./setup.sh {docker|build|run|minion|test|clone|highstate|cleanup|permissions|all} [exclude_dirs...]
```

## Options

1. `docker`: Sets up Docker on the host system.
   - Purpose: Ensures that Docker is installed and properly configured.

2. `build`: Builds the Salt Master Docker container.
   - Purpose: Creates the Docker image for the Salt Master.

3. `run`: Runs the Salt Master container.
   - Purpose: Starts the Salt Master service in a Docker container.

4. `minion`: Sets up the Salt Minion on the host.
   - Purpose: Installs and configures the Salt Minion to connect to the Salt Master.

5. `test`: Tests the connection between Salt Master and Minion.
   - Purpose: Verifies that the Salt Master can communicate with the Minion.

6. `clone`: Clones the PDP (Project Development Platform) repository.
   - Purpose: Adds the PDP project to the Salt-Docker management system.

7. `highstate`: Runs the Salt highstate.
   - Purpose: Applies all configured Salt states to bring the system to the desired configuration.

8. `cleanup`: Stops and removes Docker containers, networks, and volumes.
   - Purpose: Cleans up the Docker environment for a fresh start or troubleshooting.

9. `permissions [exclude_dirs...]`: Adjusts ownership of files in /opt.
   - Purpose: Ensures that the current user has proper access to project files.
   - Usage: Specify directories to exclude from permission changes as additional arguments.

10. `all [exclude_dirs...]`: Runs all steps in sequence.
    - Purpose: Performs a complete setup of the Salt-Docker system.
    - Usage: Optionally specify directories to exclude from permission changes.

## Examples

1. Complete setup:
   ```bash
   sudo ./setup.sh all
   ```

2. Setup with permission adjustment (excluding certain directories):
   ```bash
   sudo ./setup.sh all salt-docker pdp
   ```

3. Clean up the Docker environment:
   ```bash
   sudo ./setup.sh cleanup
   ```

4. Adjust permissions for specific directories:
   ```bash
   sudo ./setup.sh permissions salt-docker pdp
   ```

## Best Practices

- Run the script with sudo privileges to ensure proper access for all operations.
- Use the `cleanup` option before running `all` if you want to start from a clean slate.
- Regularly check the Salt Master and Minion logs for any issues or important information.

## Troubleshooting

If you encounter issues:
1. Use the `cleanup` option to reset the Docker environment.
2. Check the Salt Master and Minion logs for error messages.
3. Ensure all required ports are open and accessible.
4. Verify that the Salt configuration files are correctly set up.

For further assistance, please refer to the project documentation or contact the system administrator.
