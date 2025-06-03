# Docker Run Quick Start Guide

## Minimal Setup

```bash
# 1. Build the image
docker build -t thetadata/terminal .

# 2. Run with your credentials
docker run -d \
  --name theta-terminal \
  -p 25510:25510 \
  -p 25520:25520 \
  -p 11000:11000 \
  -p 10000:10000 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  thetadata/terminal

# 3. Check it's running
docker logs theta-terminal
curl http://localhost:25510/v2/system/mdds/status
```

## Full Setup with Volumes

```bash
# 1. Create directories
mkdir -p config logs theta-data

# 2. Copy config files to config directory
cp config_*.properties config/

# 3. Run with all options
docker run -d \
  --name theta-terminal \
  --restart unless-stopped \
  -p 25510:25510 \
  -p 25520:25520 \
  -p 11000:11000 \
  -p 10000:10000 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  -e JAVA_OPTS="-Xms4G -Xmx8G" \
  -v $(pwd)/config:/opt/theta/config \
  -v $(pwd)/logs:/opt/theta/logs \
  -v $(pwd)/theta-data:/root/ThetaData/ThetaTerminal \
  thetadata/terminal
```

## Multiple Instances Example

```bash
# Production instance
docker run -d \
  --name theta-prod \
  -p 25510:25510 -p 25520:25520 -p 11000:11000 -p 10000:10000 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  -v $(pwd)/config:/opt/theta/config \
  -v $(pwd)/logs/prod:/opt/theta/logs \
  thetadata/terminal \
  --config=/opt/theta/config/config_0.properties

# Test instance (different ports)
docker run -d \
  --name theta-test \
  -p 25511:25511 -p 25521:25521 -p 11001:11001 -p 10001:10001 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  -v $(pwd)/config:/opt/theta/config \
  -v $(pwd)/logs/test:/opt/theta/logs \
  thetadata/terminal \
  --config=/opt/theta/config/config_1.properties
```

## Common Commands

```bash
# View logs
docker logs -f theta-terminal

# Stop container
docker stop theta-terminal

# Start container
docker start theta-terminal

# Remove container
docker rm -f theta-terminal

# View running containers
docker ps

# Check health
docker inspect theta-terminal --format='{{.State.Health.Status}}'
```
