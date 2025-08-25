#!/bin/bash

###############################################################################
# Tasmota Backend Development Environment Setup Script
#
# This script installs essential development tools for the Tasmota Backend
# IoT project on Debian-based systems (Debian/Ubuntu).
#
# Installs:
# - Go 1.25 (latest official binary)
# - PostgreSQL client tools (no server)
# - Mosquitto client tools (no broker)
# - Make utility and build tools
# - Basic development utilities
#
# Requirements:
# - Debian-based system with passwordless sudo
# - Existing Docker, npm, and Python installations
# - Internet connection for downloads
#
# Usage: sudo ./install-dev-tools.sh
###############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Go version to install
GO_VERSION="1.25.0"
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_DOWNLOAD_URL="https://go.dev/dl/${GO_ARCHIVE}"

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
  echo -e "\n${GREEN}=== $1 ===${NC}"
}

# Error handling
error_exit() {
  log_error "$1"
  exit 1
}

# Check if running as root
check_root() {
  if [[ $EUID -eq 0 ]]; then
    log_warning "This script should be run as a regular user with sudo privileges"
    log_warning "It will use sudo when needed"
  fi
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Verify existing installations
check_prerequisites() {
  log_header "Checking Prerequisites"

  # Check for existing tools
  if command_exists docker; then
    DOCKER_VERSION=$(docker --version)
    log_success "Docker found: $DOCKER_VERSION"
  else
    log_warning "Docker not found - make sure to install it separately"
  fi

  if command_exists npm; then
    NPM_VERSION=$(npm --version)
    log_success "npm found: version $NPM_VERSION"
  else
    log_warning "npm not found - make sure to install it separately"
  fi

  if command_exists python3; then
    PYTHON_VERSION=$(python3 --version)
    log_success "Python found: $PYTHON_VERSION"
  else
    log_warning "Python not found - make sure to install it separately"
  fi
}

# Update system packages
update_system() {
  log_header "Updating System Packages"
  sudo apt update
  log_success "System packages updated"
}

# Install basic utilities and build tools
install_utilities() {
  log_header "Installing Basic Utilities and Build Tools"

  local packages=(
    "curl"
    "wget"
    "unzip"
    "git"
    "build-essential"
    "make"
    "jq"
    "htop"
    "tree"
    "ca-certificates"
    "apt-transport-https"
    "gnupg"
    "lsb-release"
  )

  log_info "Installing packages: ${packages[*]}"
  sudo apt install -y "${packages[@]}"
  log_success "Basic utilities and build tools installed"
}

# Install PostgreSQL client tools only
install_postgresql_client() {
  log_header "Installing PostgreSQL Client Tools"

  log_info "Installing PostgreSQL client tools (no server)"
  sudo apt install -y postgresql-client-17 postgresql-client-common pgcli

  if command_exists psql; then
    PSQL_VERSION=$(psql --version)
    log_success "PostgreSQL client installed: $PSQL_VERSION"
  else
    error_exit "PostgreSQL client installation failed"
  fi
}

# Install Mosquitto client tools only
install_mosquitto_client() {
  log_header "Installing Mosquitto Client Tools"

  log_info "Installing Mosquitto client tools (no broker)"
  sudo apt install -y mosquitto-clients

  if command_exists mosquitto_pub; then
    log_success "Mosquitto clients installed successfully"
    log_info "Available commands: mosquitto_pub, mosquitto_sub"
  else
    error_exit "Mosquitto client installation failed"
  fi
}

# Install Go 1.25 from official binary
install_go() {
  log_header "Installing Go $GO_VERSION"

  # Check if Go is already installed
  if command_exists go; then
    CURRENT_GO_VERSION=$(go version | cut -d' ' -f3)
    log_info "Found existing Go installation: $CURRENT_GO_VERSION"

    if [[ "$CURRENT_GO_VERSION" == "go$GO_VERSION" ]]; then
      log_success "Go $GO_VERSION is already installed"
      return 0
    else
      log_warning "Different Go version found. Upgrading to $GO_VERSION"
    fi
  fi

  # Remove existing Go installation
  if [[ -d "/usr/local/go" ]]; then
    log_info "Removing existing Go installation"
    sudo rm -rf /usr/local/go
  fi

  # Download Go binary
  log_info "Downloading Go $GO_VERSION..."
  cd /tmp
  wget -q --show-progress "$GO_DOWNLOAD_URL" || error_exit "Failed to download Go"

  # Verify download
  if [[ ! -f "$GO_ARCHIVE" ]]; then
    error_exit "Go archive not found after download"
  fi

  # Extract and install
  log_info "Installing Go to /usr/local/go"
  sudo tar -C /usr/local -xzf "$GO_ARCHIVE"

  # Cleanup
  rm -f "$GO_ARCHIVE"

  # Verify installation
  if [[ -x "/usr/local/go/bin/go" ]]; then
    GO_INSTALLED_VERSION=$(/usr/local/go/bin/go version)
    log_success "Go installed: $GO_INSTALLED_VERSION"
  else
    error_exit "Go installation failed"
  fi
}

# Configure environment variables
configure_environment() {
  log_header "Configuring Environment Variables"

  # Profile files to update
  local profile_files=("$HOME/.bashrc" "$HOME/.profile")

  # Go environment variables
  local go_config='
# Go environment variables
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin'

  for profile_file in "${profile_files[@]}"; do
    if [[ -f "$profile_file" ]]; then
      # Check if Go config already exists
      if grep -q "export GOROOT=/usr/local/go" "$profile_file"; then
        log_info "Go environment already configured in $profile_file"
      else
        log_info "Adding Go environment to $profile_file"
        echo "$go_config" >>"$profile_file"
      fi
    fi
  done

  # Create GOPATH directories
  mkdir -p "$HOME/go/bin"
  mkdir -p "$HOME/go/pkg"
  mkdir -p "$HOME/go/src"

  log_success "Environment variables configured"
  log_info "GOROOT: /usr/local/go"
  log_info "GOPATH: $HOME/go"
  log_warning "Run 'source ~/.bashrc' or restart terminal to apply changes"
}

# Verify all installations
verify_installations() {
  log_header "Verifying Installations"

  local success=true

  # Check Go
  if /usr/local/go/bin/go version >/dev/null 2>&1; then
    GO_VER=$(/usr/local/go/bin/go version | cut -d' ' -f3)
    log_success "Go: $GO_VER"
  else
    log_error "Go installation failed"
    success=false
  fi

  # Check PostgreSQL client
  if command_exists psql; then
    PSQL_VER=$(psql --version | cut -d' ' -f3)
    log_success "PostgreSQL client: $PSQL_VER"
  else
    log_error "PostgreSQL client not found"
    success=false
  fi

  # Check Mosquitto clients
  if command_exists mosquitto_pub; then
    log_success "Mosquitto clients: Available"
  else
    log_error "Mosquitto clients not found"
    success=false
  fi

  # Check make
  if command_exists make; then
    MAKE_VER=$(make --version | head -1)
    log_success "Make: $MAKE_VER"
  else
    log_error "Make not found"
    success=false
  fi

  # Check git
  if command_exists git; then
    GIT_VER=$(git --version)
    log_success "Git: $GIT_VER"
  else
    log_error "Git not found"
    success=false
  fi

  # Check jq
  if command_exists jq; then
    JQ_VER=$(jq --version)
    log_success "jq: $JQ_VER"
  else
    log_error "jq not found"
    success=false
  fi

  if [[ "$success" == true ]]; then
    log_success "All installations verified successfully!"
  else
    error_exit "Some installations failed verification"
  fi
}

# Print usage instructions
print_usage_info() {
  log_header "Next Steps"

  cat <<EOF
${GREEN}Development environment setup complete!${NC}

${BLUE}To start using the tools:${NC}
1. Run: ${YELLOW}source ~/.bashrc${NC} (to apply Go environment variables)
2. Verify Go: ${YELLOW}/usr/local/go/bin/go version${NC}
3. Test PostgreSQL client: ${YELLOW}psql --version${NC}
4. Test MQTT clients: ${YELLOW}mosquitto_pub --help${NC}

${BLUE}For the Tasmota Backend project:${NC}
1. Navigate to project directory: ${YELLOW}cd $(pwd)${NC}
2. Initialize Go modules: ${YELLOW}go mod tidy${NC}
3. Build project: ${YELLOW}make build${NC} (if Makefile exists)
4. Run tests: ${YELLOW}go test ./...${NC}

${BLUE}Database connection (external PostgreSQL):${NC}
- Use connection string from .env file
- Example: ${YELLOW}psql "\$DATABASE_URL"${NC}

${BLUE}MQTT testing:${NC}
- Publish: ${YELLOW}mosquitto_pub -h <broker> -t <topic> -m <message>${NC}
- Subscribe: ${YELLOW}mosquitto_sub -h <broker> -t <topic>${NC}

${GREEN}Happy coding!${NC}
EOF
}

# Main installation function
main() {
  log_header "Tasmota Backend Development Environment Setup"

  check_root
  check_prerequisites
  update_system
  install_utilities
  install_postgresql_client
  install_mosquitto_client
  install_go
  configure_environment
  verify_installations
  print_usage_info

  log_success "Installation completed successfully!"
  log_info "You may need to run 'source ~/.bashrc' to apply environment changes"
}

# Run main function
main "$@"
