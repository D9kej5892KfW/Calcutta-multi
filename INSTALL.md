# Installation Guide - Claude Agent Telemetry System

## Quick Setup

### 1. Download Grafana Binary
```bash
# Download Grafana v11.1.0
mkdir -p bin
cd bin
wget https://dl.grafana.com/oss/release/grafana-11.1.0.linux-amd64.tar.gz
tar -xzf grafana-11.1.0.linux-amd64.tar.gz
cp grafana-v11.1.0/bin/grafana .
chmod +x grafana
cd ..
```

### 2. Start Services
```bash
# Start Loki
./scripts/start-loki.sh

# Start Grafana  
./scripts/start-grafana.sh
```

### 3. Access Dashboard
- **URL**: http://localhost:3000
- **Login**: admin/admin
- **Dashboard**: "Claude Agent Telemetry - Comprehensive Dashboard"

## Notes
- Grafana binaries are excluded from git due to size (200MB+)
- Download required on first setup
- All configuration and scripts are included