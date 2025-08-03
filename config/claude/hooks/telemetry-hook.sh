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

# Escape JSON strings to prevent parsing errors
escape_json_string() {
    local input="$1"
    # Escape backslashes first, then quotes, then other special characters
    echo "$input" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g; s/$/\\n/g' | tr -d '\n'
}

# Create telemetry log entry using jq for proper JSON encoding
LOG_ENTRY=$(jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg level "INFO" \
  --arg event_type "$EVENT_TYPE" \
  --arg hook_event "$HOOK_EVENT" \
  --arg session_id "$SESSION_ID" \
  --arg project_path "$PROJECT_PATH" \
  --arg project_name "$PROJECT_NAME" \
  --arg tool_name "$TOOL_NAME" \
  --argjson telemetry_enabled "$TELEMETRY_ENABLED" \
  --arg file_path "$FILE_PATH" \
  --argjson size_bytes "$FILE_SIZE" \
  --argjson outside_scope "$OUTSIDE_SCOPE" \
  --arg command "${COMMAND:-}" \
  --arg search_pattern "${PATTERN:-}" \
  --arg search_path "${SEARCH_PATH:-}" \
  --argjson raw_input "$JSON_INPUT" \
  '{
    timestamp: $timestamp,
    level: $level,
    event_type: $event_type,
    hook_event: $hook_event,
    session_id: $session_id,
    project_path: $project_path,
    project_name: $project_name,
    tool_name: $tool_name,
    telemetry_enabled: $telemetry_enabled,
    action_details: {
      file_path: $file_path,
      size_bytes: $size_bytes,
      outside_project_scope: $outside_scope,
      command: $command,
      search_pattern: $search_pattern,
      search_path: $search_path
    },
    metadata: {
      claude_version: "4.0",
      telemetry_version: "1.0.0",
      user_id: "jeff",
      scope: "project"
    },
    raw_input: $raw_input
  }')

# Create logs directory if it doesn't exist (minimal backup only)
mkdir -p "$PROJECT_PATH/data/logs"

# Keep minimal backup log (crash recovery only)
echo "$LOG_ENTRY" >> "$PROJECT_PATH/data/logs/claude-telemetry.jsonl"

# Send to Loki if enabled
if [[ "$TELEMETRY_ENABLED" == "true" ]]; then
    # Create Loki-compatible log entry
    LOKI_TIMESTAMP="${TIMESTAMP}Z"
    LOKI_TIMESTAMP_NS=$(date -d "$TIMESTAMP" +%s%N)
    
    # Create simplified log message for Loki
    LOG_MESSAGE="tool:$TOOL_NAME event:$EVENT_TYPE session:$SESSION_ID"
    
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
        ["$LOKI_TIMESTAMP_NS", "$LOG_MESSAGE"]
      ]
    }
  ]
}
EOF
)
    
    # Debug: Log the payload being sent
    echo "=== DEBUG $(date) ===" >> /tmp/loki_debug.log
    echo "PAYLOAD: $LOKI_PAYLOAD" >> /tmp/loki_debug.log
    
    # Send to Loki (fire and forget, don't block if Loki is down)
    curl -s -H "Content-Type: application/json" \
         -XPOST "http://localhost:3100/loki/api/v1/push" \
         -d "$LOKI_PAYLOAD" >> /tmp/loki_debug.log 2>&1 &
fi

# Return success to continue tool execution
echo '{"continue": true}'
exit 0