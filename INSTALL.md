# Installation Guide - Claude Agent Telemetry System

## Prerequisites

### System Requirements
- Claude Code installed and working
- Linux/WSL environment (tested on Ubuntu/Debian)
- Bash shell (4.0+)
- `jq` command-line JSON processor
- `curl` for HTTP requests
- At least 500MB free disk space

### Install Dependencies
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install jq curl

# CentOS/RHEL
sudo yum install jq curl

# macOS
brew install jq curl
```

## Binary Setup

### Option 1: Use Existing Binaries (Recommended)
If you cloned the complete project, binaries are already included:
```bash
# Verify binaries exist and are executable
ls -la bin/
./bin/loki --version    # Should show v3.5.3
./bin/grafana --version # Should show v11.1.0
```

### Option 2: Download Binaries (If Missing)

#### Download Loki Binary
```bash
mkdir -p bin
cd bin

# Download Loki v3.5.3
wget https://github.com/grafana/loki/releases/download/v3.5.3/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
mv loki-linux-amd64 loki
chmod +x loki
rm loki-linux-amd64.zip

cd ..
```

#### Download Grafana Binary (Optional)
```bash
cd bin

# Download Grafana v11.1.0 (if not already present)
if [ ! -f grafana ]; then
  wget https://dl.grafana.com/oss/release/grafana-11.1.0.linux-amd64.tar.gz
  tar -xzf grafana-11.1.0.linux-amd64.tar.gz
  cp grafana-v11.1.0/bin/grafana .
  cp grafana-v11.1.0/bin/grafana-server .
  chmod +x grafana grafana-server
fi

cd ..
```

## Telemetry Activation

### 1. Enable Telemetry
```bash
# Enable telemetry for this project
touch config/.telemetry-enabled

# Verify activation marker exists
ls -la config/.telemetry-enabled
```

### 2. Verify Hook Configuration
```bash
# Check hook script permissions
chmod +x config/claude/hooks/telemetry-hook.sh

# Verify hook configuration
cat config/claude/settings.json
```

### 3. Start Services
```bash
# Start Loki service (required)
./scripts/start-loki.sh

# Verify Loki is running
./scripts/status.sh

# Start Grafana dashboard (optional)
./scripts/start-grafana.sh
```

### 4. Access Dashboard
- **Loki API**: http://localhost:3100
- **Grafana URL**: http://localhost:3000 (if started)
- **Grafana Login**: admin/admin
- **Dashboard**: "Claude Agent Telemetry - Comprehensive Dashboard"

## Verification

### Test Telemetry Collection
```bash
# Use Claude Code tools in this project to generate telemetry
# Check if logs are being created
tail -5 data/logs/claude-telemetry.jsonl

# Query Loki directly
./scripts/query-examples.sh

# Check system status
./scripts/status.sh
```

### Expected Output
```bash
# System status should show:
# - Loki Service: Running (PID: xxxxx)
# - Telemetry: Enabled
# - Hook Script: Present
# - Claude Config: Present
```

## Troubleshooting

### Common Issues

**"Command not found: jq"**
```bash
# Install jq dependency
sudo apt install jq  # Ubuntu/Debian
brew install jq      # macOS
```

**"Permission denied" on scripts**
```bash
# Make all scripts executable
chmod +x scripts/*.sh
chmod +x config/claude/hooks/telemetry-hook.sh
```

**"Loki not ready"**
```bash
# Check if binary exists and is executable
ls -la bin/loki
./bin/loki --version

# Check logs for errors
tail -20 logs/loki.log

# Restart Loki
./scripts/stop-loki.sh
./scripts/start-loki.sh
```

**"No telemetry data"**
```bash
# Verify telemetry is enabled
ls -la config/.telemetry-enabled

# Test hook manually
echo '{"tool_name":"test"}' | config/claude/hooks/telemetry-hook.sh

# Check Claude Code is using this project's config
# (Restart Claude Code session if needed)
```

## System Requirements

### Storage
- **Binaries**: ~400MB (Loki: 120MB, Grafana: 220MB)
- **Data**: ~1-5MB per day of telemetry
- **Logs**: Minimal (rotated automatically)

### Performance
- **Memory**: Loki ~50-100MB, Grafana ~200MB
- **CPU**: Minimal impact (background services)
- **Network**: Local only (no external connections)

### Security
- All data stored locally
- No external network communication
- Project-scoped monitoring only
- No file content captured (metadata only)

## Next Steps

After successful installation:
1. Use Claude Code tools to generate telemetry data
2. Explore the Grafana dashboard for real-time monitoring
3. Run example queries to understand the data structure
4. Review `README.md` for operational procedures
5. Check `docs/claude-agent-telemetry.md` for detailed architecture

## Shutdown Procedures

When you're finished using the telemetry system:

### Quick Shutdown (Recommended)
```bash
./scripts/shutdown.sh
```
**Features:** Graceful shutdown, status verification, process cleanup

### Alternative Methods
```bash
# Ultra-quick shutdown
./scripts/stop-all.sh

# Individual services
./scripts/stop-loki.sh      # Stop Loki only
./scripts/stop-grafana.sh   # Stop Grafana only
```

### Restart After Shutdown
```bash
# Restart both services
./scripts/start-loki.sh
./scripts/start-grafana.sh

# Or use individual start scripts as needed
```