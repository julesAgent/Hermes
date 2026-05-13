#!/bin/bash

# --- STRICT MODE ---
set -euo pipefail

# ======================= Configuration =======================
# Hugging Face Space uses UID 1000 and usually expects app on port 7860
export PORT="${PORT:-7860}"
export HERMES_WEBUI_HOST="0.0.0.0"
export HERMES_WEBUI_PORT="$PORT"

# Persistence Configuration
export DATA_DIR="/app/data"
export HERMES_HOME="$DATA_DIR/hermes"
export HERMES_WEBUI_STATE_DIR="$HERMES_HOME/webui"
export HERMES_WEBUI_DEFAULT_WORKSPACE="$DATA_DIR/workspace"
export HF_HOME="/tmp/.cache/huggingface"

# Hugging Face Bucket URL
# Example: hf://buckets/username/bucket-name
export BUCKET_URL="${BUCKET_URL:-}"

echo "[$(date +'%T')] --- Hermes WebUI / Hugging Face Persistence (Buckets) ---"

# 1. Directory Setup
mkdir -p "$HERMES_HOME" "$HERMES_WEBUI_STATE_DIR" "$HERMES_WEBUI_DEFAULT_WORKSPACE" "$HF_HOME"

# 2. HF Token & Bucket Check
if [[ -z "${HF_TOKEN:-}" ]]; then
    echo "[WARNING] HF_TOKEN is missing. Persistence will be disabled."
else
    if [[ -z "$BUCKET_URL" ]]; then
        echo "[WARNING] BUCKET_URL is missing. Persistence will be disabled."
    else
        echo "[Restore] Syncing from bucket: $BUCKET_URL"
        # Sync from Bucket to Local on startup
        hf sync "$BUCKET_URL" "$DATA_DIR" --token "$HF_TOKEN" || echo "[ERROR] Failed to initial sync from bucket."

        # 3. Background Sync
        echo "[Scheduler] Starting background synchronization every 5 minutes..."
        (
            while true; do
                sleep 300
                echo "[$(date +'%T')] [Sync] Uploading changes to bucket..."
                hf sync "$DATA_DIR" "$BUCKET_URL" --token "$HF_TOKEN" || echo "[ERROR] Failed to sync to bucket."
            done
        ) &
    fi
fi

# 4. Start Application
echo "[System] Starting Hermes WebUI on port $PORT..."
cd /app
exec python3 server.py
