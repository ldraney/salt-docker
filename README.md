# Salt-Docker Project Management System

## Overview

Salt-Docker is a robust, flexible system for managing multiple Docker-based projects on a single host using SaltStack. It provides an idempotent setup process, automated project discovery, and centralized configuration management.

This repo uses the [docker-salt-master project](https://github.com/cdalvaro/docker-salt-master) as a tool and guide. 
To update the cloned version in this repo, please run:
```
docker compose run --rm updater
```

## Key Featuresid

- Automated Docker installation and configuration
- Salt master running in a Docker container
- Host system configured as a Salt minion
- Dynamic project discovery and configuration
- Idempotent setup and configuration process

## System Requirements

- Ubuntu (latest LTS version recommended)
- sudo access

## Quick Start

1. Clone this repository:
   ```
   git clone https://github.com/ldraney/salt-docker.git /opt/salt-docker
   ```

2. Run the setup script:
   ```
   cd /opt/salt-docker
   sudo ./setup.sh
   ```

3. Apply the Salt state:
   ```
   sudo salt-call --local state.highstate
   ```

## File Structure

```
/opt/salt-docker/
├── Dockerfile
├── docker-compose.yml
├── setup.sh
├── README.md
└── salt/
    ├── base/
    │   └── top.sls
    └── project_includes/
        └── scan_projects.sls
```

- `Dockerfile`: Defines the Salt master container
- `docker-compose.yml`: Configures the Salt master service
- `setup.sh`: Installs Docker and sets up the initial environment
- `salt/base/top.sls`: The top file for Salt, includes the project scanner
- `salt/project_includes/scan_projects.sls`: Dynamically discovers and includes project configurations

## Adding New Projects

1. Clone your project into the `/opt` directory:
   ```
   git clone https://github.com/ldraney/your-project.git /opt/your-project
   ```

2. Create a `salt` directory in your project with an `init.sls` file:
   ```
   mkdir -p /opt/your-project/salt
   touch /opt/your-project/salt/init.sls
   ```

3. Define your project's Salt state in `init.sls`. Example:
   ```yaml
   install_project_dependencies:
     pkg.installed:
       - pkgs:
         - git
         - build-essential

   setup_project:
     cmd.run:
       - name: docker-compose up -d
       - cwd: /opt/your-project
       - require:
         - pkg: install_project_dependencies
   ```

4. Apply the Salt state:
   ```
   sudo salt-call --local state.highstate
   ```

The system will automatically detect your new project and apply its configuration.

## How It Works

1. The `top.sls` file includes `project_includes.scan_projects`.
2. `scan_projects.sls` scans the `/opt` directory for subdirectories.
3. For each subdirectory with a `salt/init.sls` file, it dynamically includes that project's Salt state.
4. When `state.highstate` is run, Salt applies all discovered project configurations.

## Single Docker Command Setup

To set up the entire system with a single Docker command, you can use:

```bash
docker run -d --name salt-master \
  -v /opt/salt-docker/salt:/srv/salt \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --network host \
  salt/salt-master
```

This command:
- Starts a Salt master container
- Mounts the Salt configuration from `/opt/salt-docker/salt`
- Gives the container access to the Docker socket for managing other containers
- Uses host networking for simplified communication

After running this command, you can execute Salt commands using:

```bash
docker exec salt-master salt-call --local state.highstate
```

## Best Practices

1. Keep project-specific configurations in each project's `salt/init.sls`.
2. Use `docker-compose.yml` files within each project for container definitions.
3. Regularly update the Salt-Docker system and your projects.
4. Use version control for both the Salt-Docker repository and your projects.

## Troubleshooting

- If a project is not being detected, ensure it has a `salt/init.sls` file.
- Check Salt and Docker logs for error messages:
  ```
  docker logs salt-master
  sudo journalctl -u salt-minion
  ```
- Ensure the Salt minion on the host is running:
  ```
  sudo systemctl status salt-minion
  ```

## Contributing

Contributions to improve Salt-Docker are welcome. Please submit pull requests or open issues on the GitHub repository.
