# Claude Agent Telemetry System

A comprehensive security audit and monitoring system for Claude Code agent activities. This system provides real-time telemetry collection, structured logging, and centralized log aggregation to enable security monitoring, behavioral analysis, and forensic investigation of AI agent operations.

## 🎯 **Why Use This System?**

**Problem**: As AI agents become more prevalent in development workflows, there's a critical need to monitor their behavior, audit their actions, and ensure they operate within defined security boundaries.

**Solution**: This system provides:
- **Complete Activity Monitoring**: Every Claude tool usage is captured and logged
- **Security Boundary Enforcement**: Detects when agents access files outside project scope
- **Forensic Analysis**: Structured logs enable post-incident investigation
- **Real-time Alerting**: (Future) Automated detection of suspicious patterns
- **Compliance Support**: Audit trail for regulatory and security requirements

## 🏗️ **How It Works**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Claude Code   │───▶│  Telemetry Hook  │───▶│  Dual Storage   │
│   Tool Usage    │    │  (Pre/Post Tool) │    │  Local + Loki   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│    Grafana      │◀───│  Query Engine    │◀───│   Loki Server   │
│   Dashboard     │    │  (LogQL/HTTP)    │    │   (Port 3100)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

**Data Flow:**
1. **Tool Execution**: User/Claude uses any tool (Read, Write, Bash, Edit, etc.)
2. **Hook Trigger**: Claude Code automatically calls telemetry hook (Pre/Post execution)
3. **Data Capture**: Hook extracts metadata, tool arguments, file paths, timing
4. **Dual Storage**: Logs saved locally (backup) and sent to Loki (analysis)
5. **Query/Analysis**: Real-time queries via HTTP API or future Grafana dashboard

## 📁 Project Structure

```
agent-telemetry/
├── README.md                          # This file
├── docs/
│   └── claude-agent-telemetry.md      # Detailed documentation
├── config/
│   ├── claude/
│   │   ├── settings.json              # Claude Code hook configuration
│   │   └── hooks/
│   │       └── telemetry-hook.sh      # Main telemetry capture script
│   ├── loki/
│   │   ├── loki.yaml                  # Main Loki configuration
│   │   └── loki-full.yaml             # Full Loki configuration with retention
│   └── .telemetry-enabled             # Activation marker file
├── bin/
│   └── loki                           # Loki binary (v3.5.3)
├── data/
│   ├── logs/                          # Local backup logs
│   │   ├── claude-telemetry.jsonl     # Main telemetry log
│   │   └── archive/                   # Daily/historical logs
│   └── loki/                          # Loki storage backend
│       ├── chunks/                    # Log data chunks
│       ├── rules/                     # Query rules
│       └── compactor/                 # Data compaction workspace
├── logs/                              # System/service logs
│   ├── loki.log                       # Loki server logs
│   └── loki.pid                       # Loki process ID (when running)
├── scripts/                           # Management scripts
│   ├── start-loki.sh                  # Start Loki service
│   ├── stop-loki.sh                   # Stop Loki service
│   ├── start-grafana.sh               # Start Grafana dashboard
│   ├── stop-grafana.sh                # Stop Grafana dashboard
│   ├── status.sh                      # Check system status
│   └── query-examples.sh              # Example Loki queries
└── temp/                              # Temporary/download files
```

## 🚀 Quick Start

### 1. Start Loki Service
```bash
./scripts/start-loki.sh
```

### 2. Check System Status
```bash
./scripts/status.sh
```

### 3. View Telemetry Data
```bash
./scripts/query-examples.sh
```

### 4. Start Grafana Dashboard
```bash
./scripts/start-grafana.sh
```

### 5. Access Dashboard
- **URL**: http://localhost:3000
- **Login**: admin/admin
- **Dashboard**: "Claude Agent Telemetry Dashboard"

### 6. Stop Services
```bash
./scripts/stop-loki.sh
./scripts/stop-grafana.sh
```

## 🔍 Query Examples

```bash
# All telemetry data
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="claude-telemetry"}'

# File operations only
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="claude-telemetry", event="file_read"}'
```

## 📊 Architecture

- **Hook System**: Captures all Claude Code tool usage
- **Dual Storage**: Local JSONL files + Loki aggregation
- **Project Scoped**: Only monitors agent-telemetry project
- **Security Focused**: Detects out-of-scope file access
- **Query Ready**: Structured logs for forensic analysis

## 📊 **What Gets Monitored**

Every Claude Code tool usage generates telemetry with rich context:

### **Tool Categories Captured**
- **File Operations**: `Read`, `Write`, `Edit`, `MultiEdit` - File access patterns, content changes
- **Command Execution**: `Bash` - Shell commands, arguments, working directory
- **Code Analysis**: `Grep`, `Glob` - Search patterns, file discovery
- **Task Management**: `TodoWrite` - Task creation, status changes
- **AI Operations**: `Task` (sub-agents), `WebFetch`, `WebSearch` - Delegation patterns

### **Metadata Collected**
```json
{
  "timestamp": "2025-08-01T03:15:02-04:00",
  "tool_name": "Read",
  "event_type": "file_read",
  "session_id": "16f668a2-ee15-47fa-b541-fc415b2513d2",
  "action_details": {
    "file_path": "/home/user/project/src/main.py",
    "size_bytes": 2048,
    "outside_project_scope": false
  },
  "security_flags": {
    "outside_project_scope": false,
    "sensitive_path": false
  }
}
```

## 🚀 **Quick Start Guide**

### **Prerequisites**
- Claude Code installed and working
- `jq` command-line tool (for JSON processing)
- `curl` (for HTTP requests)
- Bash shell environment

### **Initial Setup**
```bash
# 1. Clone or setup the project directory
cd /path/to/agent-telemetry

# 2. Verify structure
ls -la  # Should show config/, data/, scripts/, etc.

# 3. Check Loki binary
./bin/loki --version  # Should show v3.5.3

# 4. Start the monitoring system
./scripts/start-loki.sh
```

### **Verification Steps**
```bash
# Check system status
./scripts/status.sh

# Generate some test telemetry (use Claude tools)
# Then query recent data
./scripts/query-examples.sh

# Monitor real-time logs
tail -f data/logs/claude-telemetry.jsonl
```

## 🔧 **Configuration**

### **Enable/Disable Telemetry**
```bash
# Enable telemetry for this project
touch config/.telemetry-enabled

# Disable telemetry
rm config/.telemetry-enabled
```

### **Adjust Loki Settings**
Edit `config/loki/loki.yaml`:
```yaml
limits_config:
  ingestion_rate_mb: 10        # Increase for high-volume logging
  retention_period: 30d        # Adjust retention (requires compactor)
```

### **Hook Configuration**
The telemetry hook is automatically configured via `config/claude/settings.json`. To manually adjust:
```json
{
  "hooks": {
    "PreToolUse": [{"matcher": "*", "hooks": [{"type": "command", "command": "path/to/hook"}]}],
    "PostToolUse": [{"matcher": "*", "hooks": [{"type": "command", "command": "path/to/hook"}]}]
  }
}
```

## 🔍 **Advanced Query Examples**

### **Security Monitoring**
```bash
# Detect out-of-scope file access
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="claude-telemetry"} |= "outside_project_scope.*true"'

# Monitor command execution patterns
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="claude-telemetry", event="command_execution"}'

# Track file modification patterns
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="claude-telemetry", event="file_write"}'
```

### **Usage Analytics**
```bash
# Most used tools (requires LogQL aggregation)
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query=count by (tool) (rate({service="claude-telemetry"}[1h]))'

# Session activity timeline
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="claude-telemetry", session="your-session-id"}'

# File access frequency
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="claude-telemetry"} |= "file_path"'
```

## 📈 **Performance & Resource Usage**

### **System Impact**
- **Hook Overhead**: ~1-5ms per tool execution
- **Memory Usage**: Loki ~50-100MB, Hook ~minimal
- **Disk Usage**: ~1-5MB per day of telemetry data
- **Network**: Local HTTP only (localhost:3100)

### **Scaling Considerations**
- **High Volume**: Increase `ingestion_rate_mb` in Loki config
- **Long Retention**: Enable compactor with retention policies
- **Multiple Projects**: Deploy separate instances or use tenant labels
- **Performance Monitoring**: Watch `logs/loki.log` for ingestion errors

## 🔒 **Security & Privacy**

### **Data Collection Policy**
- **Scope**: Only monitors agent-telemetry project (unless configured otherwise)
- **Content**: Tool usage metadata, NO file contents
- **Network**: All data stays local (no external transmission)
- **Storage**: Local filesystem only

### **Security Features**
- **Boundary Detection**: Flags file access outside project scope
- **Session Isolation**: Unique session IDs for forensic analysis
- **Tamper Evidence**: Immutable log entries with timestamps
- **Access Control**: Localhost-only API access

### **Privacy Considerations**
- File paths are logged (consider sensitive directory names)
- Command arguments are captured (avoid passwords in CLI)
- No file content or user input is stored
- Session IDs enable correlation but are project-local

## 🚨 **Troubleshooting**

### **Common Issues**

**"Loki not ready" Error**
```bash
# Check if Loki is running
./scripts/status.sh

# Check logs for errors
tail -20 logs/loki.log

# Restart if needed
./scripts/stop-loki.sh && ./scripts/start-loki.sh
```

**"No telemetry data" Issue**
```bash
# Verify hook configuration
cat config/claude/settings.json

# Check hook script permissions
ls -la config/claude/hooks/telemetry-hook.sh

# Verify telemetry is enabled
ls -la config/.telemetry-enabled

# Test hook manually
echo '{"tool_name":"test"}' | config/claude/hooks/telemetry-hook.sh
```

**"Permission denied" Errors**
```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x config/claude/hooks/telemetry-hook.sh

# Check data directory permissions
ls -la data/
mkdir -p data/logs/archive
```

### **Debug Mode**
Add debug output to hook script:
```bash
# Edit config/claude/hooks/telemetry-hook.sh
# Add at top: set -x  # Enable debug tracing
# Add logging: echo "DEBUG: $MESSAGE" >> /tmp/hook-debug.log
```

## 🔮 **Future Enhancements**

### **Phase 3: Dashboard (Planned)**
- Grafana dashboard with pre-built panels
- Real-time monitoring and alerting
- Historical trend analysis
- Security incident detection

### **Phase 4: Advanced Analytics (Roadmap)**
- Machine learning anomaly detection
- Behavioral pattern analysis
- Risk scoring and classification
- Integration with security tools (SIEM)

## 📖 **Additional Resources**

- **Detailed Architecture**: `docs/claude-agent-telemetry.md`
- **Loki Documentation**: https://grafana.com/docs/loki/
- **LogQL Query Language**: https://grafana.com/docs/loki/latest/logql/
- **Claude Code Hooks**: https://docs.anthropic.com/claude-code/hooks