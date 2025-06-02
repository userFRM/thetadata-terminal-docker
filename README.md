# ThetaData Terminal Docker

A professional Docker implementation for ThetaData Terminal that provides cross-platform support (macOS, Windows, Linux) with minimal latency overhead.

## Features

- 🚀 **Zero-latency overhead** - Docker adds only microseconds to local API calls
- 🌍 **Cross-platform support** - Works identically on macOS, Windows, and Linux
- 🔧 **Easy configuration** - Simple environment variables and config files
- 🏃 **Multiple instances** - Run production and test terminals simultaneously
- 🔒 **Secure credential handling** - Multiple options for credential management
- 📊 **Health monitoring** - Built-in health checks and logging

## Quick Start

### Prerequisites

- Docker installed on your system
- Docker Compose (optional, for easier management)
- ThetaData account credentials
- ThetaTerminal.jar file (download from ThetaData)

### 1. Clone and Setup

```bash
git clone https://github.com/userfrm/thetadata-terminal-docker.git
cd thetadata-terminal-docker

# Download ThetaTerminal.jar and place it in the root directory
# wget https://download-stable.thetadata.us/
```

### 2. Build the Docker Image

```bash
docker build -t thetadata/terminal .
```

### 3. Run with Docker Compose (Recommended)

```bash
# Create config directory
mkdir -p config logs

# Copy default config
cp config_0.properties config/

# Edit docker-compose.yml and add your credentials
# Then start the service
docker-compose up -d
```

### 4. Run with Docker CLI

```bash
# Option 1: With environment variables
docker run -d \
  --name theta-terminal \
  -p 25510:25510 \
  -p 25520:25520 \
  -p 11000:11000 \
  -p 10000:10000 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  -v $(pwd)/config:/opt/theta/config \
  -v $(pwd)/logs:/opt/theta/logs \
  thetadata/terminal

# Option 2: With credentials file
echo "your-email@example.com" > creds.txt
echo "your-password" >> creds.txt
chmod 600 creds.txt

docker run -d \
  --name theta-terminal \
  -p 25510:25510 \
  -p 25520:25520 \
  -p 11000:11000 \
  -p 10000:10000 \
  -v $(pwd)/creds.txt:/creds.txt:ro \
  -v $(pwd)/config:/opt/theta/config \
  -v $(pwd)/logs:/opt/theta/logs \
  thetadata/terminal --creds-file=/creds.txt
```

## Configuration

### Ports

| Port | Description | Protocol |
|------|-------------|----------|
| 25510 | HTTP REST API | HTTP |
| 25520 | WebSocket API | WS |
| 11000 | Python API (MDDS) | TCP |
| 10000 | Python API (FPSS) | TCP |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| THETA_USERNAME | Your ThetaData username | - |
| THETA_PASSWORD | Your ThetaData password | - |
| JAVA_OPTS | Java memory settings | -Xms1G -Xmx4G |
| TZ | Timezone | UTC |

### Memory Configuration

Adjust memory based on your needs:

```yaml
# Low-end machine (< 8GB RAM)
JAVA_OPTS: "-Xms1G -Xmx2G"

# Standard machine (8-16GB RAM)
JAVA_OPTS: "-Xms2G -Xmx6G"

# High-end machine (> 16GB RAM)
JAVA_OPTS: "-Xms4G -Xmx12G"
```

## Multiple Instances

Run production and test terminals simultaneously:

```bash
# Start production terminal
docker-compose up -d theta-terminal

# Start test terminal (connects to stage servers)
docker-compose --profile test up -d theta-terminal-test
```

## WebSocket Example

Test the WebSocket connection with Python:

```python
import asyncio
import websockets

async def stream_trades():
    async with websockets.connect('ws://127.0.0.1:25520/v1/events') as websocket:
        req = {
            'msg_type': 'STREAM_BULK',
            'sec_type': 'OPTION',
            'req_type': 'TRADE',
            'add': True,
            'id': 0
        }
        await websocket.send(str(req))
        while True:
            response = await websocket.recv()
            print(response)

asyncio.get_event_loop().run_until_complete(stream_trades())
```

## Health Check

Check terminal status:

```bash
# Using curl
curl http://localhost:25510/v1/system/status

# Using Docker
docker exec theta-terminal curl http://localhost:25510/v1/system/status
```

## Logs

View logs:

```bash
# Real-time logs
docker logs -f theta-terminal

# Saved logs
ls -la ./logs/
```

## Performance

Docker adds minimal overhead:
- **Network latency**: < 1ms for local connections
- **Memory overhead**: ~50MB for container
- **CPU overhead**: < 1% when idle

The dominant latency factor remains the internet connection to ThetaData servers (~50-100ms), not Docker.

## Troubleshooting

### Container won't start
- Check credentials are correct
- Ensure ThetaTerminal.jar is in the build directory
- Verify ports are not already in use

### Connection issues
- Check firewall settings
- Ensure Docker network is properly configured
- Verify ThetaData servers are accessible

### Memory issues
- Reduce JAVA_OPTS memory allocation
- Decrease HTTP_CONCURRENCY in config

## Security

- Never commit credentials to version control
- Use credentials files with proper permissions (600)
- Consider using Docker secrets for production
- Restrict port exposure in production environments

## License

This Docker implementation is provided as-is. ThetaData Terminal is proprietary software - ensure you have proper licensing from ThetaData.

## Support

- Docker issues: Create an issue in this repository
- ThetaData issues: https://discord.thetadata.us/
- API documentation: https://http-docs.thetadata.us/
