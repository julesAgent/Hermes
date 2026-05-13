# Deployment Guide: Hermes WebUI on Hugging Face Spaces (via GHCR & Buckets)

This guide explains how to deploy Hermes WebUI to Hugging Face Spaces using the image built and pushed to GitHub Container Registry (GHCR) and persisting data via Hugging Face Buckets.

## Overview

1.  **GitHub Action:** Automatically builds a Docker image from the `Dockerfile` in your repo and pushes it to `ghcr.io/your-username/your-repo`.
2.  **Hugging Face Space:** Uses `Dockerfile.hf`, which pulls the image from GHCR and adds persistence logic using `hf sync`.

## Step 1: Push to GitHub

Push your code to GitHub. The GitHub Action will trigger and build your image. Check the **Actions** tab in your GitHub repository to ensure the build completes successfully.

## Step 2: Create a Bucket for Persistence

1.  Go to Hugging Face and create a new **Bucket**.
2.  Note the Bucket URL (e.g., `hf://buckets/username/my-bucket`).

## Step 3: Configure Dockerfile.hf

Open `Dockerfile.hf` and update the first line:

```dockerfile
FROM ghcr.io/your-username/hermes-webui:latest
```

Replace `your-username/hermes-webui` with your actual GHCR repository path.

## Step 4: Create the Space

1.  Go to [huggingface.co/new-space](https://huggingface.co/new-space).
2.  Name it (e.g., `hermes-webui`).
3.  Select **Docker** as the SDK.
4.  Choose the **Blank** template or **Dockerfile**.

## Step 5: Configure Secrets

In your Space settings:

1.  Go to **Settings** > **Variables and secrets**.
2.  Add a New Secret:
    *   **Name:** `HF_TOKEN`
    *   **Value:** Your HF User Access Token (with `write` permission).
3.  Add a New Secret:
    *   **Name:** `BUCKET_URL`
    *   **Value:** Your Bucket URL (from Step 2).

## Step 6: Upload Files to Space

Upload `Dockerfile.hf` (rename it to `Dockerfile`) and `run_hf.sh` to your Hugging Face Space repository.

## Persistence Details

The `run_hf.sh` script uses the `hf` CLI tool to sync the `/app/data` directory with your bucket on startup and every 5 minutes in the background. This ensures your sessions, settings, and `.env` files are saved.
