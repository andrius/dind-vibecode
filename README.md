# Docker-in-Docker Claude Development Environment

A containerized development environment with a convenient wrapper script that provides Docker-in-Docker capabilities, Claude Code, and multiple development tools. Supports parallel sessions and flexible volume mounting.

## Purpose & Motivation

This project was built to enable **safe AI-assisted development** in isolated environments. The key motivation is running AI coding tools like Claude Code in **YOLO mode** (no confirmations) without risking damage to your host system.

**Why containerized AI development?**
- 🛡️ **Safety First**: Run destructive AI operations in isolation
- 🚀 **YOLO Mode**: Let AI make changes without confirmations, safely
- 🔒 **Host Protection**: Your main system remains untouched
- 🧪 **Experimentation**: Try radical refactoring and changes risk-free
- ⚡ **Parallel Work**: Multiple isolated AI sessions simultaneously

The container provides a complete development environment where Claude Code can freely modify, refactor, or even break code without affecting your host machine. Perfect for letting AI loose on your codebase with confidence.

## Features

- **Vibecode Wrapper**: Simple command-line interface for container management
- **Parallel Sessions**: Run multiple isolated development environments simultaneously
- **Docker-in-Docker**: Full Docker CE with compose plugin for nested containerization
- **Claude Code**: Pre-installed and configured for AI-assisted development
- **Multi-language Support**: Python 3.13 and Node.js 22
- **Flexible Volume Mounting**: Mount any host directory into containers
- **Session Management**: Persistent named sessions or temporary auto-cleanup containers

## Installation

### One-Line Install (Recommended)

Install vibecode globally with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/andrius/dind-vibecode/main/install.sh | bash
```

This will:
- Install vibecode to `~/.local/bin/vibecode` 
- Download the project to `~/.cache/vibecode/`
- Verify Docker is available and accessible
- Test the installation

After installation, you can use `vibecode` from anywhere (add `~/.local/bin` to your PATH if needed).

### Manual Installation

Alternatively, clone and use locally:

```bash
git clone https://github.com/andrius/dind-vibecode.git
cd dind-vibecode
./vibecode --help
```

### Prerequisites
- Docker installed on host
- Claude Code authentication configured in `~/.claude` or `~/.claude.json`

## Quick Start

### Usage Examples

```bash
# Run Claude Code (current directory mounted automatically)
vibecode claude "what is this project about"

# Check Claude version
vibecode claude --version

# Interactive shell
vibecode bash

# Mount real project directory
vibecode --volume /home/ak/code/some/backend:/workspace claude analyze

# Use persistent named session for a project
vibecode --session myproject claude "analyze this project"

# Continue working in the same session later
vibecode --session myproject claude "implement the suggested changes"

# List running sessions
vibecode --list
```

## YOLO Mode Setup & Usage

For safe AI-assisted development without confirmations, you can run Claude Code in YOLO mode within the isolated container:

### One-time Setup
First, acknowledge the permissions (one-time setup per container):
```bash
vibecode claude --dangerously-skip-permissions
# Select "yes" when prompted, then exit
```

### YOLO Mode Examples
```bash
# Basic YOLO mode - let AI make changes without confirmations
vibecode claude --print "refactor this entire codebase" --dangerously-skip-permissions --verbose

# YOLO mode with specific project
vibecode --volume /home/ak/code/some/backend:/workspace claude --print "fix all bugs and optimize performance" --dangerously-skip-permissions

# Continuous YOLO session with JSON output
vibecode claude --continue --print "implement new features" --dangerously-skip-permissions --verbose --output-format stream-json | jq

# YOLO mode in persistent session
vibecode --session danger-zone claude --print "completely restructure this project" --dangerously-skip-permissions
```

### Why YOLO Mode in Containers?
- **Complete Safety**: AI can destroy, refactor, or break code without affecting your host
- **Fearless Experimentation**: Try radical changes you'd never risk on your main codebase
- **Rapid Iteration**: No confirmations needed - let AI work at full speed
- **Easy Recovery**: Simply restart the container if things go wrong

## Vibecode Wrapper

The `vibecode` script provides an easy interface to run containerized development environments:

**Basic Usage:**
- `vibecode claude "your question"` - Quick Claude Code execution
- `vibecode bash` - Interactive shell with full toolset
- `vibecode --help` - Show all available options

**Session Management:**
- Each `vibecode` command creates a persistent container by default
- `vibecode --session name` - Create/reuse a named session for a specific project
- `vibecode --list` - List all running sessions
- Sessions persist until manually removed - great for ongoing work

**Volume Mounting:**
- Current directory mounted to `/workspace` by default
- `--volume src:dest` for custom mounts
- Multiple volumes supported

## Session Cleanup

Since containers are persistent, you'll want to clean them up occasionally:

```bash
# List all running vibecode sessions
vibecode --list

# Remove a specific session
docker rm -f session-name

# Remove all vibecode sessions (clean slate)
docker rm -f $(docker ps -aq --filter "label=vibecode-session")
```

**When to clean up:**
- When you're done with a project
- Running low on disk space
- Too many containers running

## Architecture

- **Base**: Python 3.13 on Debian Trixie with Docker-in-Docker support
- **Containers**: Each session runs in its own isolated container
- **Working Directory**: `/workspace` (mount your project directories here)
- **Authentication**: Claude Code config automatically copied from host

## Available Tools

- Claude Code (v1.0.89+)
- Python 3.13.7
- Docker 28.3.3+ with Compose
- Node.js 22.18.0 LTS
- **Passwordless Sudo**: Install additional packages without prompts

### Package Installation

The container's `developer` user has full sudo access without password prompts, enabling installation of additional tools:

```bash
# Install system packages
vibecode bash
sudo apt-get update && sudo apt-get install -y vim git build-essential

# Install Python packages globally
sudo pip install numpy pandas matplotlib

# Install Node.js packages globally  
sudo npm install -g typescript @angular/cli
```

## Security Notes

- Runs in privileged mode (required for Docker-in-Docker)
- Mounts Docker socket for host Docker access
- Claude configuration mounted for authentication