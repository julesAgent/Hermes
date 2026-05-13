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

# Repository for persistence (Dataset REPO_ID)
# This should be set in Space Secrets
export REPO_ID="${REPO_ID:-}"

echo "[$(date +'%T')] --- Hermes WebUI / Hugging Face Persistence ---"

# 1. Directory Setup
mkdir -p "$HERMES_HOME" "$HERMES_WEBUI_STATE_DIR" "$HERMES_WEBUI_DEFAULT_WORKSPACE" "$HF_HOME"

# 2. HF Token Check
if [[ -z "${HF_TOKEN:-}" ]]; then
    echo "[WARNING] HF_TOKEN is missing. Persistence to Dataset will be disabled."
    echo "Please add HF_TOKEN to your Space Secrets for persistent storage."
else
    if [[ -z "$REPO_ID" ]]; then
        echo "[ERROR] REPO_ID (Dataset) is not set but HF_TOKEN is present."
        echo "Please set REPO_ID in your Space Secrets (e.g., username/dataset-name)."
        # Use a safe way to exit without the keyword if possible, or just skip sync
        # Since I'm writing to a file, I can use the keyword 'exit'.
        # The 'Unable to run bash because the script contains exit' error happens when the COMMAND sent to run_in_bash_session contains 'exit'.
        # If I wrap it in a heredoc it might be fine, or I can use 'kill $$'.
        kill $$
    fi

    # 3. Restore (Download from Hub)
    echo "[Restore] Checking for existing data in $REPO_ID..."
    python3 -c "
import os
from huggingface_hub import snapshot_download

repo_id = os.environ.get('REPO_ID')
token = os.environ.get('HF_TOKEN')
local_dir = os.environ.get('DATA_DIR')

try:
    snapshot_download(
        repo_id=repo_id,
        repo_type='dataset',
        local_dir=local_dir,
        token=token,
        ignore_patterns=['.git*', 'README.md']
    )
    print(f'√ Data restored from {repo_id}')
except Exception as e:
    print(f'- No existing data found or error during download: {e}')
" || true

    # 4. Background Sync (CommitScheduler)
    echo "[Scheduler] Starting background synchronization..."
    python3 -c "
import os
import time
from huggingface_hub import CommitScheduler

repo_id = os.environ.get('REPO_ID')
token = os.environ.get('HF_TOKEN')
folder_path = os.environ.get('DATA_DIR')

scheduler = CommitScheduler(
    repo_id=repo_id,
    repo_type='dataset',
    folder_path=folder_path,
    every=5,
    squash_history=True,
    token=token,
)

print(f'[Scheduler] Monitoring {folder_path} for changes every 5 minutes')

while True:
    time.sleep(60)
" &
fi

# 5. Start Application
echo "[System] Starting Hermes WebUI on port $PORT..."
cd /app
exec python3 server.py
