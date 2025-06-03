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

# Create necessary directories (all possible locations ThetaTerminal might use)
echo "Creating directories..."
mkdir -p "${THETA_LOGS}"
mkdir -p "${THETA_HOME}/.theta"
mkdir -p "/root/.theta"
mkdir -p "/root/ThetaData/ThetaTerminal"
mkdir -p "/root/.ThetaData/ThetaTerminal"

# Debug info
echo "Current user: $(whoami)"
echo "User ID: $(id -u)"
echo "Group ID: $(id -g)"
echo "HOME: ${HOME}"
echo "THETA_HOME: ${THETA_HOME}"
echo "Directory listing of /root:"
ls -la /root/

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
        # Cleanup function
        cleanup() {
            rm -f "$TEMP_CREDS"
        }
        trap cleanup EXIT
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

# Execute ThetaTerminal directly
exec $CMD
