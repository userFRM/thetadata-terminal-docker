# ThetaData Terminal Docker Image
# Production-grade container for cross-platform deployment
# Supports: Linux (amd64/arm64), macOS, Windows

# Use specific Java version for reproducibility
# Java 24 recommended for optimal performance
ARG JAVA_VERSION=24
FROM openjdk:${JAVA_VERSION}-slim AS base

# Metadata
LABEL org.opencontainers.image.authors="ThetaData Community"
LABEL org.opencontainers.image.description="Production-ready Docker image for ThetaData Terminal"
LABEL org.opencontainers.image.version="1.8.6"
LABEL org.opencontainers.image.source="https://github.com/userfrm/thetadata-terminal-docker"
LABEL org.opencontainers.image.documentation="https://github.com/userfrm/thetadata-terminal-docker/blob/main/README.md"
LABEL org.opencontainers.image.licenses="MIT"

# Build arguments for flexibility
ARG THETA_VERSION=latest
ARG THETA_DOWNLOAD_URL=https://download-stable.thetadata.us/ThetaTerminal.jar
ARG DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV THETA_VERSION=${THETA_VERSION} \
    THETA_HOME=/opt/theta \
    THETA_CONFIG=/opt/theta/config \
    THETA_LOGS=/opt/theta/logs \
    THETA_DATA=/opt/theta/data \
    JAVA_OPTS="-Xms4G -Xmx8G" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

# Create non-root user (commented out for compatibility)
# RUN groupadd -g 1000 theta && \
#     useradd -u 1000 -g theta -s /bin/bash -m theta

# Install required packages with security updates
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        bash \
        tzdata \
        gettext-base \
        file \
        procps \
        net-tools \
        iputils-ping \
        dnsutils \
        jq \
        bc \
        && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Update CA certificates
    update-ca-certificates

# Create directory structure with proper permissions
RUN mkdir -p ${THETA_HOME} ${THETA_CONFIG} ${THETA_LOGS} ${THETA_DATA} && \
    mkdir -p ${THETA_HOME}/.theta && \
    mkdir -p /root/.theta && \
    mkdir -p /root/ThetaData/ThetaTerminal && \
    mkdir -p /root/.ThetaData/ThetaTerminal && \
    # Set permissions (if using non-root user)
    # chown -R theta:theta ${THETA_HOME} /root && \
    chmod -R 755 ${THETA_HOME} /root

# Download and verify ThetaTerminal.jar in a separate stage for caching
FROM base AS downloader
ARG THETA_DOWNLOAD_URL

# Download with retry logic
RUN set -ex && \
    for i in 1 2 3; do \
        curl -fsSL --retry 3 --retry-delay 5 \
            -o ${THETA_HOME}/ThetaTerminal.jar \
            "${THETA_DOWNLOAD_URL}" && \
        break || \
        if [ $i -eq 3 ]; then \
            echo "ERROR: Failed to download ThetaTerminal.jar after 3 attempts"; \
            exit 1; \
        fi; \
        echo "Retry $i failed, waiting..."; \
        sleep 10; \
    done && \
    # Verify the JAR file
    if [ ! -f ${THETA_HOME}/ThetaTerminal.jar ]; then \
        echo "ERROR: ThetaTerminal.jar not found after download"; \
        exit 1; \
    fi && \
    # Check file type
    file ${THETA_HOME}/ThetaTerminal.jar | grep -q "Java archive" || \
        (echo "ERROR: Downloaded file is not a valid JAR" && exit 1) && \
    # Check minimum file size (10MB)
    [ $(stat -c%s "${THETA_HOME}/ThetaTerminal.jar") -ge 10000000 ] || \
        (echo "ERROR: JAR file too small, likely corrupted" && exit 1) && \
    # Set proper permissions
    chmod 644 ${THETA_HOME}/ThetaTerminal.jar

# Final stage
FROM base

# Copy JAR from downloader stage
COPY --from=downloader ${THETA_HOME}/ThetaTerminal.jar ${THETA_HOME}/ThetaTerminal.jar

# Copy configuration files
COPY config_0.properties config_1.properties ${THETA_CONFIG}/

# Copy and prepare entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    # Ensure script has Unix line endings
    sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh

# Copy monitoring script if it exists
COPY scripts/monitor.sh* /usr/local/bin/

# Set up health check script
RUN echo '#!/bin/sh\ncurl -f http://localhost:25510/v2/system/fpss/status || curl -f http://localhost:25510/v2/system/mdds/status || exit 1' \
    > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Create volume mount points
VOLUME ["${THETA_CONFIG}", "${THETA_LOGS}", "${THETA_DATA}"]

# Set working directory
WORKDIR ${THETA_HOME}

# Expose all required ports
# 25510: HTTP REST API
# 25520: WebSocket API
# 11000: Python API (MDDS)
# 10000: Python API (FPSS)
EXPOSE 25510 25520 11000 10000

# Configure health check
HEALTHCHECK --interval=240s \
            --timeout=10s \
            --start-period=60s \
            --retries=3 \
            CMD /usr/local/bin/healthcheck.sh

# Switch to non-root user (if enabled)
# USER theta

# Set entrypoint and default command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["--config=/opt/theta/config/config_0.properties"]

# Build-time metadata
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}"
