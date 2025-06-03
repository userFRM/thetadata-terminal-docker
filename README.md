# ThetaData Terminal Docker

[![Docker Build](https://github.com/userFRM/thetadata-terminal-docker/actions/workflows/main.yml/badge.svg)](https://github.com/userFRM/thetadata-terminal-docker/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Production-ready Docker implementation for ThetaData Terminal with multi-instance support, cross-platform compatibility, and enterprise-grade configuration.

## Features

- 🚀 Cross-platform support (Linux, macOS, Windows, ARM64)
- 🔧 Multiple deployment options (Docker Run, Docker Compose)
- 🏗️ Multi-instance support for running production and test environments
- 📊 WebSocket and REST API endpoints
- 🔒 Secure credential management
- ⚡ Optimized for low latency with configurable memory settings

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+ (optional)
- ThetaData account ([Sign up here](https://www.thetadata.net/))
- 8GB+ RAM (16GB recommended)

## Quick Start

### Option 1: Using Docker Run

```bash
# Pull and run with environment variables
docker run -d \
  --name theta-terminal \
  -p 25510:25510 \
  -p 25520:25520 \
  -p 11000:11000 \
  -p 10000:10000 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  -e JAVA_OPTS="-Xms4G -Xmx8G" \
  ghcr.io/userfrm/thetadata/terminal:latest

# Check logs
docker logs -f theta-terminal

# Test connection
curl http://localhost:25510/v2/system/mdds/status
```

### Option 2: Using Docker Compose (Recommended)

1. **Clone the repository:**
```bash
git clone https://github.com/userFRM/thetadata-terminal-docker.git
cd thetadata-terminal-docker
```

2. **Configure credentials:**
```bash
cp .env.example .env
# Edit .env with your credentials
nano .env
```

3. **Start the terminal:**
```bash
docker-compose up -d
```

## Configuration

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 25510 | REST API | HTTP endpoints for data queries |
| 25520 | WebSocket | Real-time streaming data |
| 11000 | MDDS Socket | Query-based data access |
| 10000 | FPSS Socket | Streaming data access |

### Memory Settings

Configure based on your system and usage:

```bash
# Standard (Recommended)
JAVA_OPTS="-Xms4G -Xmx8G"

# High Performance
JAVA_OPTS="-Xms8G -Xmx16G"

# Low Memory
JAVA_OPTS="-Xms2G -Xmx4G"
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `THETA_USERNAME` | Your ThetaData email | Required |
| `THETA_PASSWORD` | Your ThetaData password | Required |
| `JAVA_OPTS` | Java memory settings | `-Xms4G -Xmx8G` |
| `TZ` | Timezone | `UTC` |

## Advanced Usage

### Running Multiple Instances

Run production and test terminals simultaneously:

```bash
# Production (default ports)
docker run -d \
  --name theta-prod \
  -p 25510:25510 -p 25520:25520 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  ghcr.io/userfrm/thetadata/terminal:latest

# Test environment (different ports)
docker run -d \
  --name theta-test \
  -p 25511:25511 -p 25521:25521 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  -v $(pwd)/config:/opt/theta/config \
  ghcr.io/userfrm/thetadata/terminal:latest \
  --config=/opt/theta/config/config_1.properties
```

### Using Credentials File

For better security, use a credentials file instead of environment variables:

```bash
# Create credentials file
cat > creds.txt << EOF
your-email@example.com
your-password
EOF
chmod 600 creds.txt

# Run with credentials file
docker run -d \
  --name theta-terminal \
  -p 25510:25510 -p 25520:25520 \
  -v $(pwd)/creds.txt:/creds.txt:ro \
  ghcr.io/userfrm/thetadata/terminal:latest \
  --creds-file=/creds.txt
```

### Persistent Storage

Mount volumes for logs and configuration:

```bash
docker run -d \
  --name theta-terminal \
  -p 25510:25510 -p 25520:25520 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  -v $(pwd)/config:/opt/theta/config \
  -v $(pwd)/logs:/opt/theta/logs \
  -v $(pwd)/data:/root/.theta \
  ghcr.io/userfrm/thetadata/terminal:latest
```

## API Examples

### REST API

```bash
# Get stock quote
curl "http://localhost:25510/v2/snapshot/stock/quote?root=AAPL"

# Get historical data
curl "http://localhost:25510/v2/hist/stock/trade?root=AAPL&start_date=20240101&end_date=20240101"

# Check system status
curl "http://localhost:25510/v2/system/mdds/status"
curl "http://localhost:25510/v2/system/fpss/status"
```

### WebSocket Streaming

```python
import asyncio
import websockets
import json

async def stream_trades():
    uri = "ws://localhost:25520/v1/events"

    async with websockets.connect(uri) as websocket:
        # Subscribe to trades
        subscribe = {
            "msg_type": "STREAM_BULK",
            "sec_type": "OPTION",
            "req_type": "TRADE",
            "add": True,
            "id": 0
        }

        await websocket.send(json.dumps(subscribe))

        while True:
            message = await websocket.recv()
            print(json.loads(message))

asyncio.run(stream_trades())
```
[ThetaData Documentation](https://http-docs.thetadata.us/)

## Building from Source

If you want to build the image yourself:

```bash
# Clone repository
git clone https://github.com/userFRM/thetadata-terminal-docker.git
cd thetadata-terminal-docker

# Build image
docker build -t thetadata/terminal .

# Run your built image
docker run -d \
  --name theta-terminal \
  -p 25510:25510 -p 25520:25520 \
  -e THETA_USERNAME="your-email@example.com" \
  -e THETA_PASSWORD="your-password" \
  thetadata/terminal
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs theta-terminal

# Verify credentials
docker run -it --rm ghcr.io/userfrm/thetadata/terminal:latest --help
```

### Connection issues
```bash
# Test from inside container
docker exec theta-terminal curl http://localhost:25510/v2/system/mdds/status

# Check port availability
netstat -tulpn | grep -E "25510|25520"
```

### Performance issues
```bash
# Monitor resource usage
docker stats theta-terminal

# Adjust memory settings
docker run -d \
  --name theta-terminal \
  -e JAVA_OPTS="-Xms8G -Xmx16G" \
  ghcr.io/userfrm/thetadata/terminal:latest
```

## Health Monitoring

The container includes automatic health checks every 240 seconds:

```bash
# Check health status
docker inspect theta-terminal --format='{{.State.Health.Status}}'

# View health check history
docker inspect theta-terminal --format='{{range .State.Health.Log}}{{.Output}}{{end}}'
```

## License

This Docker implementation is MIT licensed. ThetaData Terminal itself requires a valid license from ThetaData.

## Support

- **Docker Issues**: [Create an issue](https://github.com/userFRM/thetadata-terminal-docker/issues)
- **ThetaData Support**: [Discord](https://discord.thetadata.us/)
- **Documentation**: [ThetaData Docs](https://http-docs.thetadata.us/)

---

Made with ❤️ by the ThetaData Community
