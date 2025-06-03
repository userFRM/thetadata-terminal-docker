# ThetaData Terminal Docker 🐳

[![Docker Build](https://github.com/userfrm/thetadata-terminal-docker/actions/workflows/main.yml/badge.svg)](https://github.com/userfrm/thetadata-terminal-docker/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-grade Docker implementation for ThetaData Terminal that provides seamless cross-platform support with enterprise-level reliability and performance.

## ✨ Features

- 🚀 **Ultra-low latency** - Native performance with < 1ms Docker overhead
- 🌍 **Universal compatibility** - Runs identically on macOS, Windows, Linux, and ARM64
- 🔧 **Enterprise configuration** - Environment-based config with validation
- 🏗️ **Multi-instance support** - Run production and test environments simultaneously
- 🔒 **Security-first design** - Credential encryption and isolation
- 📊 **Production monitoring** - Health checks and comprehensive logging
- 🎯 **Auto-recovery** - Automatic reconnection and graceful degradation

## 📋 Requirements

- Docker Engine 20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- Docker Compose 2.0+ (included with Docker Desktop)
- ThetaData account ([Sign up](https://www.thetadata.net/))
- 8GB+ RAM (16GB recommended)
- Java 17+ (included in container)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/userfrm/thetadata-terminal-docker.git
cd thetadata-terminal-docker
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your credentials
nano .env  # or use your preferred editor
```

Set these required values in `.env`:
```env
THETA_USERNAME=your-email@example.com
THETA_PASSWORD=your-password
```

### 3. Build and Launch

```bash
# Build the Docker image
docker-compose build

# Start the terminal
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
curl http://localhost:25510/v2/system/mdds/status
curl http://localhost:25510/v2/system/fpss/status
```

## ⚙️ Configuration

### Port Mapping

| Port | Service | Description |
|------|---------|-------------|
| 25510 | REST API | HTTP endpoints for data queries |
| 25520 | WebSocket | Real-time streaming data |
| 11000 | MDDS Socket | Legacy Python API support |
| 10000 | FPSS Socket | Legacy streaming support |

### Memory Configuration

The recommended memory configuration is `-Xms4G -Xmx8G`. Adjust in `.env`:

```env
# Recommended (default)
JAVA_OPTS=-Xms4G -Xmx8G -XX:+UseG1GC

# Low memory systems
JAVA_OPTS=-Xms2G -Xmx4G -XX:+UseG1GC

# High-performance systems
JAVA_OPTS=-Xms8G -Xmx16G -XX:+UseG1GC
```

### Configuration Files

- `config/config_0.properties` - Production configuration (default)
- `config/config_1.properties` - Test/staging configuration (different ports)

Key differences for multiple instances:

| Parameter | config_0 (Production) | config_1 (Test) |
|-----------|----------------------|-----------------|
| HTTP_PORT | 25510 | 25511 |
| WS_PORT | 25520 | 25521 |
| CLIENT_PORT | 11000 | 11001 |
| STREAM_PORT | 10000 | 10001 |
| MDDS_REGION | MDDS_NJ_HOSTS | MDDS_STAGE_HOSTS |
| FPSS_REGION | FPSS_NJ_HOSTS | FPSS_STAGE_HOSTS |

## 🔧 Multiple Instances

Run production and test terminals simultaneously:

```bash
# Start production terminal only
docker-compose up -d theta-terminal

# Start both production and test terminals
docker-compose --profile test up -d

# View logs for specific instance
docker-compose logs -f theta-terminal       # Production
docker-compose logs -f theta-terminal-test  # Test
```

### Connecting to Different Servers

**Production (config_0.properties):**
- Connects to stable production servers
- Use for live trading and production systems

**Test/Stage (config_1.properties):**
- Connects to stage servers
- May have occasional reboots
- Use for development and testing

## 🚄 Performance Tuning

### Concurrent Requests

Set `HTTP_CONCURRENCY` based on your subscription:

| Subscription | Server Threads | Recommended Setting |
|--------------|----------------|---------------------|
| Free | 1 | HTTP_CONCURRENCY=1 |
| Value | 1 | HTTP_CONCURRENCY=2 |
| Standard | 2 | HTTP_CONCURRENCY=4 |
| Pro | 4 | HTTP_CONCURRENCY=4-8 |

### JVM Optimization

For different workloads:

```bash
# Low-latency trading
JAVA_OPTS="-Xms8G -Xmx8G -XX:+UseG1GC -XX:MaxGCPauseMillis=50"

# High-throughput backtesting
JAVA_OPTS="-Xms8G -Xmx16G -XX:+UseParallelGC"

# Standard usage (recommended)
JAVA_OPTS="-Xms4G -Xmx8G -XX:+UseG1GC"
```

## 📚 API Examples

### REST API

```bash
# Get real-time quote
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
        # Subscribe to trade stream
        subscribe = {
            "msg_type": "STREAM_BULK",
            "sec_type": "OPTION",
            "req_type": "TRADE",
            "add": True,
            "id": 0
        }

        await websocket.send(json.dumps(subscribe))

        # Receive messages
        while True:
            message = await websocket.recv()
            data = json.loads(message)
            print(f"Trade: {data}")

asyncio.run(stream_trades())
```

## 🔍 Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check logs
docker-compose logs theta-terminal

# Verify credentials
docker-compose config | grep THETA_

# Check for port conflicts
netstat -tulpn | grep -E "25510|25520"
```

**Connection issues:**
```bash
# Test from inside container
docker exec theta-terminal curl http://localhost:25510/v2/system/mdds/status

# Check network connectivity
docker exec theta-terminal ping -c 3 nj-a.thetadata.us
```

**Memory issues:**
```bash
# Check memory usage
docker stats theta-terminal

# Increase memory allocation in .env
JAVA_OPTS=-Xms6G -Xmx12G
```

### Health Monitoring

The container includes automatic health checks every 240 seconds:

```bash
# Check health status
docker inspect theta-terminal --format='{{.State.Health.Status}}'

# View health check logs
docker inspect theta-terminal --format='{{range .State.Health.Log}}{{.Output}}{{end}}'
```

## 🔒 Security Best Practices

1. **Never commit credentials** - Use `.env` file (already in .gitignore)
2. **Use credential files** with proper permissions:
   ```bash
   echo "your-email@example.com" > creds.txt
   echo "your-password" >> creds.txt
   chmod 600 creds.txt
   ```
3. **Restrict port access** in production:
   ```yaml
   ports:
     - "127.0.0.1:25510:25510"  # Local access only
   ```

## 📜 License

This Docker implementation is released under the MIT License. See [LICENSE](LICENSE) for details.

**Important**: ThetaData Terminal is proprietary software. You must have a valid license from ThetaData to use their terminal software.

## 🔗 Resources

- [ThetaData Documentation](https://http-docs.thetadata.us/)
- [ThetaData Discord](https://discord.thetadata.us/)
- [Docker Documentation](https://docs.docker.com/)

---

<div align="center">
  Made with ❤️ by the ThetaData Community
</div>
