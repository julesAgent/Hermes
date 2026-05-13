#!/bin/bash

# --- STRICT MODE ---
set -euo pipefail

# ======================= Configuration =======================
# Hugging Face Space uses UID 1000 and usually expects app on port 8787
export PORT="${PORT:-8787}"
export HERMES_WEBUI_HOST="0.0.0.0"
export HERMES_WEBUI_PORT="$PORT"
export HERMES_WEBUI_PASSWORD="${HERMES_WEBUI_PASSWORD:-}"

# Persistence Configuration
export DATA_DIR="/data/.hermes"

# Hugging Face Bucket URL
# Example: hf://buckets/username/bucket-name
export BUCKET_URL="${BUCKET_URL:-}"

echo "[$(date +'%T')] --- Hermes WebUI / Hugging Face Persistence (Buckets) ---"

mkdir -p "${HERMES_HOME:-/home/hermeswebui/.hermes}" \
  "${HERMES_WEBUI_STATE_DIR:-/home/hermeswebui/.hermes/webui-mvp}" \
  "${HERMES_WEBUI_DEFAULT_WORKSPACE:-/workspace}"

chown -R hermeswebui:hermeswebui \
  /data/.hermes \
  "${HERMES_HOME:-/home/hermeswebui/.hermes}" \
  "${HERMES_WEBUI_STATE_DIR:-/home/hermeswebui/.hermes/webui-mvp}" \
  "${HERMES_WEBUI_DEFAULT_WORKSPACE:-/workspace}" \
  /opt/hermes || true

chown -h hermeswebui:hermeswebui /home/hermeswebui/.hermes || true

# 1. HF Token & Bucket Check
if [[ -z "${HF_TOKEN:-}" ]]; then
    echo "[WARNING] HF_TOKEN is missing. Using built-in settings for Hugging Face Persistence (Buckets)."
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

exec /hermeswebui_init.bash
