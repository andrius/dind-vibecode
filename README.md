# Docker-in-Docker Claude Development Environment

A containerized development environment that provides Docker-in-Docker capabilities with Claude Code and multiple development tools pre-installed.

## Features

- **Docker-in-Docker**: Full Docker CE with compose plugin for nested containerization
- **Claude Code**: Pre-installed and configured for AI-assisted development
- **Multi-language Support**: Python 3.13 and Node.js 22
- **Isolated Environment**: Secure containerized workspace with volume mounting

## Quick Start

### Prerequisites
- Docker and Docker Compose installed on host
- Claude Code authentication configured in `~/.claude` or `~/.claude.json`

### Usage

```bash
# Build and start the service
docker-compose up -d

# Access the container
docker exec -it $(docker-compose ps -q dind-claude) bash

# Verify tools are working
docker exec $(docker-compose ps -q dind-claude) sh -c "claude --version && python --version && docker --version"

# Stop the service
docker-compose down
```

## Architecture

- **Base**: Python 3.13 on Debian Trixie
- **Working Directory**: `/workspace` (mounted from current directory)
- **Networking**: Isolated bridge network
- **Volumes**: Claude config inheritance and Docker socket sharing

## Available Tools

- Claude Code (v1.0.89+)
- Python 3.13.7
- Docker 28.3.3+ with Compose
- Node.js 22.18.0 LTS

## Security Notes

- Runs in privileged mode (required for Docker-in-Docker)
- Mounts Docker socket for host Docker access
- Claude configuration mounted for authentication