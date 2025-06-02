# Theta Terminal Docker Image
# Supports cross-platform deployment (Linux, macOS, Windows)

FROM openjdk:17-slim

# Set build arguments for user
ARG USER_ID=1001
ARG USER_GID=1001

# Set environment variables
ENV THETA_VERSION=latest \
    THETA_HOME=/opt/theta \
    THETA_CONFIG=/opt/theta/config \
    THETA_LOGS=/opt/theta/logs \
    JAVA_OPTS="-Xms1G -Xmx4G"

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    tzdata \
    gettext-base \
    file && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${THETA_HOME} ${THETA_CONFIG} ${THETA_LOGS}

# Download ThetaTerminal.jar with verification
RUN curl -fsSL https://download-stable.thetadata.us/ThetaTerminal.jar -o ${THETA_HOME}/ThetaTerminal.jar && \
    # Verify the JAR file was downloaded and is valid
    if [ ! -f ${THETA_HOME}/ThetaTerminal.jar ]; then \
        echo "ERROR: Failed to download ThetaTerminal.jar"; \
        exit 1; \
    fi && \
    # Check file size (should be at least 1MB)
    if [ $(stat -c%s "${THETA_HOME}/ThetaTerminal.jar") -lt 1000000 ]; then \
        echo "ERROR: Downloaded file is too small, probably not a valid JAR"; \
        echo "File size: $(stat -c%s "${THETA_HOME}/ThetaTerminal.jar") bytes"; \
        head -n 20 ${THETA_HOME}/ThetaTerminal.jar; \
        exit 1; \
    fi && \
    chmod 644 ${THETA_HOME}/ThetaTerminal.jar

# Copy configuration files
COPY config_0.properties ${THETA_CONFIG}/
COPY config_1.properties ${THETA_CONFIG}/
COPY docker-entrypoint.sh /usr/local/bin/

# Make entrypoint executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create non-root user (handle existing GID/UID)
RUN groupadd --gid ${USER_GID} theta || echo "Group already exists" && \
    useradd --uid ${USER_ID} --gid ${USER_GID} --home-dir /home/theta --create-home --shell /bin/bash theta || echo "User already exists" && \
    # Create necessary directories with proper permissions
    mkdir -p ${THETA_HOME}/.theta && \
    mkdir -p /home/theta/.theta && \
    chown -R ${USER_ID}:${USER_GID} ${THETA_HOME} && \
    chown -R ${USER_ID}:${USER_GID} /home/theta

# Switch to non-root user
USER ${USER_ID}:${USER_GID}
WORKDIR ${THETA_HOME}

# Expose all required ports
EXPOSE 25510 25520 11000 10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:25510/v1/system/status || exit 1

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["--config=/opt/theta/config/config_0.properties"]
