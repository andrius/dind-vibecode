#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/andrius/dind-vibecode.git"
CACHE_DIR="$HOME/.cache/vibecode"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/vibecode"

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command_exists docker; then
        print_error "Docker is not installed or not in PATH"
        print_error "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker is accessible (not just installed)
    if ! docker version >/dev/null 2>&1; then
        print_error "Docker is installed but not accessible"
        print_error "Make sure Docker daemon is running and you have proper permissions"
        print_error "You may need to add your user to the docker group: sudo usermod -aG docker \$USER"
        exit 1
    fi
    
    # Check if git is installed
    if ! command_exists git; then
        print_error "Git is not installed or not in PATH"
        print_error "Please install git first"
        exit 1
    fi
    
    # Check if curl is installed (should be available since they used it to run this script)
    if ! command_exists curl; then
        print_warning "curl is not available, but continuing..."
    fi
    
    print_success "Prerequisites check passed"
}

# Check if installation exists and handle updates
check_existing_installation() {
    if [[ -d "$CACHE_DIR" ]]; then
        print_info "Existing installation found at $CACHE_DIR"
        return 0
    else
        return 1
    fi
}

# Update existing installation
update_existing() {
    print_info "Updating existing installation..."
    cd "$CACHE_DIR"
    
    # Pull latest changes
    print_info "Pulling latest changes from repository"
    git pull origin main
    
    # Force rebuild containers by removing any cached images
    print_info "Cleaning up old container images to force rebuild"
    # Remove images with vibecode prefix (handles all UID-GID variants)
    docker images --format "{{.Repository}}:{{.Tag}}" | grep "^vibecode:" | xargs -r docker rmi >/dev/null 2>&1 || true
    docker image prune -f >/dev/null 2>&1 || true
    
    # Rebuild Docker image with current user's UID/GID
    print_info "Rebuilding Docker image with current user permissions"
    USER_UID=$(id -u)
    USER_GID=$(id -g)
    IMAGE_TAG="vibecode:${USER_UID}-${USER_GID}"
    
    if docker build --build-arg USER_UID="$USER_UID" --build-arg USER_GID="$USER_GID" -t "$IMAGE_TAG" . >/dev/null 2>&1; then
        print_success "Docker image rebuilt successfully: $IMAGE_TAG"
    else
        print_error "Failed to rebuild Docker image"
        print_error "You may need to rebuild it manually on next use"
    fi
    
    print_success "Installation updated successfully"
}

# Clean up existing installation (for fresh installs)
cleanup_existing() {
    if [[ -d "$CACHE_DIR" ]]; then
        print_info "Removing existing installation at $CACHE_DIR"
        rm -rf "$CACHE_DIR"
    fi
    
    if [[ -f "$BIN_PATH" ]]; then
        print_info "Removing existing binary at $BIN_PATH"
        rm -f "$BIN_PATH"
    fi
}

# Create necessary directories
create_directories() {
    print_info "Creating directories..."
    mkdir -p "$CACHE_DIR"
    mkdir -p "$BIN_DIR"
    print_success "Directories created"
}

# Clone repository (for fresh installs)
clone_repository() {
    print_info "Cloning repository from $REPO_URL"
    cd "$HOME/.cache"
    git clone "$REPO_URL" vibecode
    print_success "Repository cloned to $CACHE_DIR"
}

# Create wrapper binary
create_wrapper_binary() {
    print_info "Creating wrapper binary at $BIN_PATH"
    
    cat > "$BIN_PATH" << 'EOF'
#!/bin/bash

# Vibecode wrapper script - installed via one-liner
# This script wraps the actual vibecode binary in ~/.cache/vibecode/

set -e

CACHE_DIR="$HOME/.cache/vibecode"
VIBECODE_SCRIPT="$CACHE_DIR/vibecode"

# Check if installation exists
if [[ ! -d "$CACHE_DIR" ]]; then
    echo "Error: vibecode installation not found at $CACHE_DIR" >&2
    echo "Please reinstall using: curl -sSL https://raw.githubusercontent.com/andrius/dind-vibecode/main/install.sh | bash" >&2
    exit 1
fi

if [[ ! -f "$VIBECODE_SCRIPT" ]]; then
    echo "Error: vibecode script not found at $VIBECODE_SCRIPT" >&2
    echo "Please reinstall using: curl -sSL https://raw.githubusercontent.com/andrius/dind-vibecode/main/install.sh | bash" >&2
    exit 1
fi

# Store the original working directory before changing context
ORIGINAL_PWD="$(pwd)"

# Change to the cache directory so Docker build context is correct
cd "$CACHE_DIR"

# Execute the real vibecode script with all arguments, preserving original working directory
export ORIGINAL_PWD
exec "$VIBECODE_SCRIPT" "$@"
EOF

    chmod +x "$BIN_PATH"
    print_success "Wrapper binary created and made executable"
}

# Check PATH
check_path() {
    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        print_success "$BIN_DIR is in your PATH"
        return 0
    else
        print_warning "$BIN_DIR is not in your PATH"
        print_warning "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo -e "${YELLOW}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
        print_warning "Then restart your terminal or run: source ~/.bashrc (or your shell config file)"
        return 1
    fi
}

# Test installation
test_installation() {
    print_info "Testing installation..."
    
    # Try to run vibecode --help
    if "$BIN_PATH" --help >/dev/null 2>&1; then
        print_success "Installation test passed"
        return 0
    else
        print_error "Installation test failed"
        return 1
    fi
}

# Show usage instructions
show_usage() {
    echo
    print_success "vibecode installation completed!"
    echo
    print_info "Usage examples:"
    echo "  vibecode --help                    # Show help"
    echo "  vibecode claude --version          # Check Claude Code version"
    echo "  vibecode claude \"analyze this\"     # Quick analysis"
    echo "  vibecode bash                      # Interactive shell"
    echo "  vibecode --session myproject claude \"help me code\" # Named session"
    echo
    print_info "For YOLO mode (AI without confirmations - safe in containers):"
    echo "  vibecode claude --dangerously-skip-permissions  # One-time setup"
    echo "  vibecode claude --print \"refactor code\" --dangerously-skip-permissions"
    echo
    print_info "Documentation: https://github.com/andrius/dind-vibecode"
}

# Main installation process
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Vibecode Installer                        ║${NC}"
    echo -e "${BLUE}║      Docker-in-Docker Claude Development Environment        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Check prerequisites first
    check_prerequisites
    
    # Check if this is an update or fresh install
    if check_existing_installation; then
        print_info "Existing installation detected - performing update"
        update_existing
        # Still need to recreate the wrapper binary in case it changed
        mkdir -p "$BIN_DIR"
        create_wrapper_binary
    else
        print_info "No existing installation found - performing fresh install"
        cleanup_existing
        create_directories
        clone_repository
        create_wrapper_binary
    fi
    
    # Check PATH and test
    path_ok=true
    if ! check_path; then
        path_ok=false
    fi
    
    if test_installation; then
        show_usage
        
        if [[ "$path_ok" == false ]]; then
            echo
            print_warning "Remember to add $BIN_DIR to your PATH to use 'vibecode' from anywhere!"
        fi
    else
        print_error "Installation completed but tests failed"
        print_error "You may need to add $BIN_DIR to your PATH"
        exit 1
    fi
}

# Handle interruptions gracefully
trap 'print_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"