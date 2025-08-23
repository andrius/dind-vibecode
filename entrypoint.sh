#!/bin/bash

set -e

# Function to handle signals and cleanup
cleanup() {
    echo "Shutting down services..."
    if [ -n "$DOCKERD_PID" ]; then
        kill $DOCKERD_PID 2>/dev/null || true
        wait $DOCKERD_PID 2>/dev/null || true
    fi
    exit 0
}

# Set up signal handling
trap cleanup SIGTERM SIGINT

# Start Docker daemon in background with output redirected to reduce noise
echo "Starting Docker daemon..."
dockerd > /dev/null 2>&1 &
DOCKERD_PID=$!

# Wait for Docker daemon to be ready
echo "Waiting for Docker daemon to be ready..."
timeout=30
while [ $timeout -gt 0 ]; do
    if docker info > /dev/null 2>&1; then
        echo "Docker daemon is ready"
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo "Error: Docker daemon failed to start within 30 seconds" >&2
    exit 1
fi

echo "Container starting..."

# Fix ownership of workspace if needed
if [ -d /workspace ]; then
    chown -R developer:developer /workspace
fi

# If arguments provided, execute them as developer user
if [ $# -gt 0 ]; then
    echo "Executing command: $*"
    if [ "$1" = "bash" ] && [ $# -eq 1 ]; then
        # Interactive bash - switch to developer user with proper home
        exec su - developer -c "cd /workspace && bash"
    else
        # Other commands - execute as developer user in workspace
        exec su - developer -c "cd /workspace && $(printf '%q ' "$@")"
    fi
else
    # No arguments, keep container running
    echo "Container ready. Keeping alive..."
    while true; do
        sleep 1
    done
fi