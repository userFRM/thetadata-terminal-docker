#!/bin/bash
set -e

# Theta Terminal Docker Entrypoint Script
# Handles credential management and terminal startup

# Flexible path detection
if [ -f "/opt/theta/ThetaTerminal.jar" ]; then
    THETA_HOME=${THETA_HOME:-/opt/theta}
    THETA_CONFIG=${THETA_CONFIG:-/opt/theta/config}
    THETA_LOGS=${THETA_LOGS:-/opt/theta/logs}
elif [ -f "/home/theta/terminal/ThetaTerminal.jar" ]; then
    THETA_HOME=${THETA_HOME:-/home/theta/terminal}
    THETA_CONFIG=${THETA_CONFIG:-/home/theta/config}
    THETA_LOGS=${THETA_LOGS:-/home/theta/logs}
else
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
    echo ""
    echo "Example:"
    echo "  docker run -it -e THETA_USERNAME=user@email.com -e THETA_PASSWORD=pass thetadata/terminal"
    echo "  docker run -it -v \$(pwd)/creds.txt:/creds.txt thetadata/terminal --creds-file=/creds.txt"
}

# Check if help is requested
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
    exit 0
fi

# Create necessary directories
mkdir -p "${THETA_LOGS}"
mkdir -p "${HOME}/.theta"
mkdir -p "${THETA_HOME}/.theta"

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

        # Add credentials file to command
        CMD="$CMD --creds-file=$TEMP_CREDS"

        # Cleanup function
        cleanup() {
            rm -f "$TEMP_CREDS"
        }
        trap cleanup EXIT
    elif [[ -n "$THETA_USERNAME" ]] && [[ -z "$THETA_PASSWORD" ]]; then
        # Username provided but no password - will prompt
        CMD="$CMD $THETA_USERNAME"
    fi
    # If neither username nor password provided, terminal will prompt
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

# Execute the command
exec $CMD
