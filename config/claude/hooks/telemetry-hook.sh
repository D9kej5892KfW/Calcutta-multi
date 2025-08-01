#!/bin/bash
# Claude Code Telemetry Hook - Project Scoped
# Receives JSON input via stdin and logs tool usage for agent-telemetry project

# Read JSON input from stdin
JSON_INPUT=$(cat)

# Get current project path
PROJECT_PATH="${PWD}"

# Only activate telemetry in the agent-telemetry project
if [[ "$PROJECT_PATH" != *"agent-telemetry"* ]]; then
    echo '{"continue": true}'
    exit 0
fi

# Check for telemetry-enabled marker (optional additional control)
if [[ -f "$PROJECT_PATH/config/.telemetry-enabled" ]]; then
    TELEMETRY_ENABLED=true
else
    TELEMETRY_ENABLED=false
fi

# Extract data from JSON input
TIMESTAMP=$(date -Iseconds)
PROJECT_NAME=$(basename "$PROJECT_PATH")

# Parse Claude Code's JSON structure
TOOL_NAME=$(echo "$JSON_INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
HOOK_EVENT=$(echo "$JSON_INPUT" | jq -r '.hook_event_name // "unknown"' 2>/dev/null || echo "unknown")

# Handle different tool types
case "$TOOL_NAME" in
  "Read")
    FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
    EVENT_TYPE="file_read"
    ;;
  "Write")
    FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
    EVENT_TYPE="file_write"
    ;;
  "Edit"|"MultiEdit")
    FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
    EVENT_TYPE="file_edit"
    ;;
  "Bash")
    COMMAND=$(echo "$JSON_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
    EVENT_TYPE="command_execution"
    FILE_PATH=""
    ;;
  "Grep")
    PATTERN=$(echo "$JSON_INPUT" | jq -r '.tool_input.pattern // ""' 2>/dev/null || echo "")
    SEARCH_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.path // ""' 2>/dev/null || echo "")
    EVENT_TYPE="code_search"
    FILE_PATH="$SEARCH_PATH"
    ;;
  *)
    FILE_PATH=""
    EVENT_TYPE="tool_usage"
    ;;
esac

# Get file info if applicable
FILE_SIZE=0
OUTSIDE_SCOPE="false"
if [[ -n "$FILE_PATH" && -f "$FILE_PATH" ]]; then
    FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || stat -f%z "$FILE_PATH" 2>/dev/null || echo 0)
    if [[ "$FILE_PATH" != "$PROJECT_PATH"* ]]; then
        OUTSIDE_SCOPE="true"
    fi
fi

# Create telemetry log entry
LOG_ENTRY=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "level": "INFO",
  "event_type": "$EVENT_TYPE",
  "hook_event": "$HOOK_EVENT",
  "session_id": "$SESSION_ID",
  "project_path": "$PROJECT_PATH",
  "project_name": "$PROJECT_NAME",
  "tool_name": "$TOOL_NAME",
  "telemetry_enabled": $TELEMETRY_ENABLED,
  "action_details": {
    "file_path": "$FILE_PATH",
    "size_bytes": $FILE_SIZE,
    "outside_project_scope": $OUTSIDE_SCOPE,
    "command": "${COMMAND:-}",
    "search_pattern": "${PATTERN:-}",
    "search_path": "${SEARCH_PATH:-}"
  },
  "metadata": {
    "claude_version": "4.0",
    "telemetry_version": "1.0.0",
    "user_id": "jeff",
    "scope": "project"
  },
  "raw_input": $JSON_INPUT
}
EOF
)

# Create logs directory if it doesn't exist
mkdir -p "$PROJECT_PATH/data/logs/archive"

# Log to project-specific telemetry file (backup)
echo "$LOG_ENTRY" >> "$PROJECT_PATH/data/logs/claude-telemetry.jsonl"

# Also log to a daily file for easier management
DATE_SUFFIX=$(date +%Y-%m-%d)
echo "$LOG_ENTRY" >> "$PROJECT_PATH/data/logs/archive/claude-telemetry-$DATE_SUFFIX.jsonl"

# Send to Loki if enabled
if [[ "$TELEMETRY_ENABLED" == "true" ]]; then
    # Create Loki-compatible log entry
    LOKI_TIMESTAMP="${TIMESTAMP}Z"
    LOKI_TIMESTAMP_NS=$(date -d "$TIMESTAMP" +%s%N)
    
    LOKI_PAYLOAD=$(cat <<EOF
{
  "streams": [
    {
      "stream": {
        "service": "claude-telemetry",
        "project": "$PROJECT_NAME",
        "tool": "$TOOL_NAME",
        "event": "$EVENT_TYPE",
        "session": "$SESSION_ID",
        "scope": "project"
      },
      "values": [
        ["$LOKI_TIMESTAMP_NS", $(echo "$LOG_ENTRY" | jq -c .)]
      ]
    }
  ]
}
EOF
)
    
    # Send to Loki (fire and forget, don't block if Loki is down)
    curl -s -H "Content-Type: application/json" \
         -XPOST "http://localhost:3100/loki/api/v1/push" \
         -d "$LOKI_PAYLOAD" &>/dev/null &
fi

# Return success to continue tool execution
echo '{"continue": true}'
exit 0