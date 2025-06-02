#!/bin/bash
set -e

# Theta Terminal Docker Entrypoint Script
# Handles credential management and terminal startup

# Set paths
THETA_HOME=${THETA_HOME:-/opt/theta}
THETA_CONFIG=${THETA_CONFIG:-/opt/theta/config}
THETA_LOGS=${THETA_LOGS:-/opt/theta/logs}

# Check if ThetaTerminal.jar exists
if [ ! -f "${THETA_HOME}/ThetaTerminal.jar" ]; then
    echo "ERROR: ThetaTerminal.jar not found!"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: docker run -it thetadata/terminal [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --creds-file=FILE      Path to credentials file"
    echo "  --config=FILE          Path to config file (default: /opt/theta/config/config_0.properties)"
    echo "  --log-directory=DIR    Directory for log files (default: /opt/theta/logs)"
    echo ""
    echo "Environment variables:"
    echo "  THETA_USERNAME         Your ThetaData username"
    echo "  THETA_PASSWORD         Your ThetaData password"
    echo "  JAVA_OPTS             Java options (default: -Xms1G -Xmx4G)"
}

# Check if help is requested
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
    exit 0
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p "${THETA_LOGS}"
mkdir -p "${THETA_HOME}/.theta"
mkdir -p "/root/.theta"

# Ensure FILE_DIR exists
FILE_DIR="${FILE_DIR:-/root/.theta}"
echo "Creating FILE_DIR: ${FILE_DIR}"
mkdir -p "${FILE_DIR}"

# Debug info
echo "Current user: $(whoami)"
echo "User ID: $(id -u)"
echo "Group ID: $(id -g)"
echo "HOME: ${HOME}"
echo "THETA_HOME: ${THETA_HOME}"
echo "FILE_DIR: ${FILE_DIR}"

# Build command
CMD="java ${JAVA_OPTS} -jar ${THETA_HOME}/ThetaTerminal.jar"

# Handle credentials
CREDS_PROVIDED=false

# Check for credentials file argument
for arg in "$@"; do
    if [[ "$arg" == --creds-file=* ]]; then
        CREDS_PROVIDED=true
        break
    fi
done

# If no creds file, check for environment variables
if [[ "$CREDS_PROVIDED" == false ]]; then
    if [[ -n "$THETA_USERNAME" ]] && [[ -n "$THETA_PASSWORD" ]]; then
        # Create temporary credentials file from environment variables
        TEMP_CREDS="/tmp/theta-creds-$$"
        echo "$THETA_USERNAME" > "$TEMP_CREDS"
        echo "$THETA_PASSWORD" >> "$TEMP_CREDS"
        chmod 600 "$TEMP_CREDS"
        CMD="$CMD --creds-file=$TEMP_CREDS"
    elif [[ -n "$THETA_USERNAME" ]] && [[ -z "$THETA_PASSWORD" ]]; then
        CMD="$CMD $THETA_USERNAME"
    fi
fi

# Add log directory if not specified
LOG_DIR_SPECIFIED=false
for arg in "$@"; do
    if [[ "$arg" == --log-directory=* ]]; then
        LOG_DIR_SPECIFIED=true
        break
    fi
done

if [[ "$LOG_DIR_SPECIFIED" == false ]]; then
    CMD="$CMD --log-directory=${THETA_LOGS}"
fi

# Add all command line arguments
if [[ $# -gt 0 ]]; then
    CMD="$CMD $@"
fi

# Display startup information
echo "=========================================="
echo "Theta Terminal Docker Container"
echo "=========================================="
echo "Version: ${THETA_VERSION}"
echo "Home: ${THETA_HOME}"
echo "Config: ${THETA_CONFIG}"
echo "Logs: ${THETA_LOGS}"
echo "Java Options: ${JAVA_OPTS}"
echo "Command: $CMD"
echo "=========================================="
echo ""

# Function to wait for port to be available
wait_for_port() {
    local port=$1
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if nc -z localhost $port 2>/dev/null; then
            echo "Port $port is now available"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done

    echo "Timeout waiting for port $port"
    return 1
}

# Start ThetaTerminal
if command -v socat &> /dev/null; then
    # Start ThetaTerminal in background
    $CMD &
    THETA_PID=$!

    echo "Waiting for ThetaTerminal to start..."
    # Wait for the HTTP port to be available
    if wait_for_port 25510; then
        echo "Starting port forwarders..."
        socat TCP-LISTEN:25510,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:25510 &
        socat TCP-LISTEN:25520,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:25520 &
        socat TCP-LISTEN:11000,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:11000 &
        socat TCP-LISTEN:10000,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:10000 &
    fi

    # Wait for the main process
    wait $THETA_PID
else
    # No socat, just run directly
    exec $CMD
fi
