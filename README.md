# Docker-in-Docker Vibecoding Environment

A cross-platform containerized development environment with a convenient wrapper script that provides Docker-in-Docker capabilities, Claude Code, and multiple development tools. **Supports both macOS and Linux** with automatic platform detection and Docker dependency management.

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

- **Cross-Platform Support**: Works on both macOS and Linux with automatic platform detection
- **Vibecode Wrapper**: Simple command-line interface for container management
- **Parallel Sessions**: Run multiple isolated development environments simultaneously
- **Docker-in-Docker**: Full Docker CE with compose plugin for nested containerization
- **Complete AI Development Toolkit**: Pre-installed Claude Code, Qwen Code, Gemini CLI, Crush, OpenCode, and LLM CLI
- **Multi-language Support**: Python 3.13 and Node.js 22
- **Flexible Volume Mounting**: Mount any host directory into containers
- **Session Management**: Persistent named sessions or temporary auto-cleanup containers
- **Smart Error Handling**: Platform-specific error messages and installation guidance

## Installation

### One-Line Install (Recommended)

Install vibecode globally with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/andrius/vibecode/main/install.sh | bash
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

**Required Dependencies:**

- **Docker**: Docker Engine (Linux) or Docker Desktop (macOS)
- **Claude Code Authentication**: Configured in `~/.claude` or `~/.claude.json`

**Platform-Specific Setup:**

**Linux:**

- Docker Engine with Docker Compose plugin

**macOS:**

- Docker Desktop for Mac (required for privileged containers)
- Ensure file sharing is enabled in Docker Desktop preferences

The vibecode script automatically detects your platform and provides platform-specific error messages and guidance.

## Quick Start

### Usage Examples

```bash
# Use different AI assistants (note: each has different syntax)
vibecode claude "what is this project about"                    # Claude Code - direct args
vibecode qwen --prompt "optimize this algorithm"                # Qwen Code - requires --prompt
vibecode gemini --prompt "explain this design pattern"          # Gemini CLI - requires --prompt
vibecode opencode --prompt "refactor this function"             # OpenCode - requires --prompt
vibecode crush run "implement user authentication"              # Crush - requires 'run' subcommand
vibecode llm "summarize this codebase"                         # LLM CLI - direct args

# Check versions of AI tools
vibecode claude --version
vibecode qwen --version
vibecode gemini --version

# Interactive shell with full AI toolkit
vibecode bash

# Mount real project directory (preserves full paths, not /workspace)
vibecode --volume /home/ak/code/some/backend:/home/ak/code/some/backend claude "analyze this backend"

# Use persistent named session for a project
vibecode --session myproject claude "analyze this project"

# Continue working in the same session later with different AI tools
vibecode --session myproject qwen --prompt "optimize the database queries"
vibecode --session myproject gemini --prompt "suggest security improvements"

# List running sessions
vibecode --list
```

## YOLO Mode Setup & Usage

For safe AI-assisted development without confirmations, you can run any of the AI development tools in YOLO mode within the isolated container:

### One-time Setup

First, acknowledge the permissions (one-time setup per container):

```bash
vibecode claude --dangerously-skip-permissions
# Select "yes" when prompted, then exit
```

### YOLO Mode Examples

```bash
# Basic YOLO mode with different AI tools - let AI make changes without confirmations
vibecode claude --print "refactor this entire codebase" --dangerously-skip-permissions --verbose
vibecode qwen --prompt "optimize all algorithms in this project" --dangerously-skip-permissions
vibecode gemini --prompt "add comprehensive error handling" --dangerously-skip-permissions
vibecode crush run "implement microservices architecture" --dangerously-skip-permissions

# YOLO mode with specific project
vibecode --volume /home/ak/code/some/backend:/home/ak/code/some/backend claude --print "fix all bugs and optimize performance" --dangerously-skip-permissions

# Continuous YOLO session with JSON output
vibecode claude --continue --print "implement new features" --dangerously-skip-permissions --verbose --output-format stream-json | jq

# YOLO mode in persistent session with different AI tools
vibecode --session danger-zone claude --print "completely restructure this project" --dangerously-skip-permissions
vibecode --session danger-zone opencode --prompt "add comprehensive testing" --dangerously-skip-permissions
vibecode --session danger-zone llm "document all functions and classes" --dangerously-skip-permissions

# YOLO with development environment pre-installed
vibecode --session backend-dev bash
vibecode --session backend-dev claude --print "build a complete Go REST API with PostgreSQL" --dangerously-skip-permissions
vibecode --session backend-dev crush run "add authentication and authorization" --dangerously-skip-permissions
```

### Why YOLO Mode in Containers?

- **Complete Safety**: AI can destroy, refactor, or break code without affecting your host
- **Fearless Experimentation**: Try radical changes you'd never risk on your main codebase
- **Rapid Iteration**: No confirmations needed - let AI work at full speed
- **Easy Recovery**: Simply restart the container if things go wrong
- **Full Development Stack**: Combined with `install-dev-tools.sh`, AI has access to complete toolchains

### YOLO Wrapper Architecture

The vibecode wrapper provides several layers of protection for YOLO mode:

1. **Container Isolation**: Every AI operation runs in a disposable Docker container
2. **Volume Control**: Only explicitly mounted directories are accessible to AI
3. **User Mapping**: Proper UID/GID mapping prevents permission escalation outside container
4. **Session Management**: Named sessions allow controlled persistence, temporary sessions auto-cleanup
5. **Path Preservation**: Working directory mapping maintains familiar paths for AI context

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

- Current directory mounted to same absolute path by default (preserves host paths)
- `--volume src:dest` for custom mounts
- Multiple volumes supported
- Path preservation maintains AI context and familiar navigation

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
- **Containers**: Each session runs in its own isolated container with privileged mode
- **Working Directory**: Preserves host working directory path structure (not `/workspace`)
- **Authentication**: Claude Code config automatically copied from host (`~/.claude/` and `~/.claude.json`)
- **User Mapping**: UID/GID mapping ensures proper file permissions between host and container
- **Three-Component Design**: install.sh (installer) → vibecode (wrapper) → container (runtime environment)

## Available Tools

### AI Development Tools (Pre-installed in User Space)

All AI tools support self-upgrade and are owned by the developer user:

- **Claude Code** v1.0.92+ - Anthropic's official CLI (`@anthropic-ai/claude-code`)
- **Qwen Code** v0.0.8+ - Alibaba's AI coding assistant (`@qwen-code/qwen-code`)
- **Gemini CLI** v0.1.22+ - Google's Gemini API interface (`@google/gemini-cli`)
- **Crush** v0.7.1+ - AI-powered development tool (`@charmland/crush`)
- **OpenCode** v0.5.27+ - Open-source AI coding assistant (`opencode-ai`)
- **LLM CLI** v0.27.1+ - Universal LLM interface with Anthropic & Gemini plugins

### Core Development Stack

- Python 3.13 with pip
- Docker 28.3.3+ with Compose
- Node.js 22.18.0 LTS with npm
- **Passwordless Sudo**: Install additional packages without prompts
- **Pre-built Development Tools**: Via `install-dev-tools.sh` script

### Package Installation & AI Tool Management

#### AI Tool Self-Upgrade

All AI tools are installed in user space and can self-upgrade:

```bash
# Upgrade AI development tools
vibecode bash
claude upgrade                                    # Claude Code self-upgrade
npm update -g @anthropic-ai/claude-code          # Manual npm update
npm update -g @qwen-code/qwen-code               # Update Qwen Code
npm update -g @google/gemini-cli                 # Update Gemini CLI
npm update -g @charmland/crush                   # Update Crush
npm update -g opencode-ai                        # Update OpenCode
pip install --user --upgrade llm llm-anthropic llm-gemini  # Update LLM CLI
```

#### System Package Installation

The container's `developer` user has full sudo access without password prompts, enabling installation of additional tools:

```bash
# Install system packages
vibecode bash
sudo apt-get update && sudo apt-get install -y vim git build-essential

# Install Python packages globally
sudo pip install numpy pandas matplotlib

# Install Node.js packages globally
sudo npm install -g typescript @angular/cli

# Use pre-built development environment installer (example)
install-dev-tools.sh
```

### Pre-built Development Environment

The `install-dev-tools.sh` script provides a complete development stack for backend/IoT projects:

**Usage:**

```bash
# Enter container and install development tools
vibecode bash
install-dev-tools.sh
```

The script automatically configures environment variables (`GOROOT`, `GOPATH`) and creates necessary directories. Perfect for Go/PostgreSQL/MQTT development workflows.

## Security Notes

- Runs in privileged mode (required for Docker-in-Docker)
- Mounts Docker socket for host Docker access
- Claude configuration mounted for authentication
