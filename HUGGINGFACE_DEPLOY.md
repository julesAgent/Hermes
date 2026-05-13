# Deployment Guide: Hermes WebUI on Hugging Face Spaces

This guide explains how to deploy Hermes WebUI to Hugging Face Spaces with persistent storage using a Hugging Face Dataset.

## Prerequisites

1.  A [Hugging Face account](https://huggingface.co/join).
2.  A [User Access Token](https://huggingface.co/settings/tokens) with `write` permissions.

## Step 1: Create a Dataset for Persistence

The application saves sessions and configurations to a Dataset.

1.  Go to [huggingface.co/new-dataset](https://huggingface.co/new-dataset).
2.  Name it (e.g., `hermes-webui-data`).
3.  Set it to **Private** (recommended, as it will store your session history).
4.  Note the Repository ID (e.g., `username/hermes-webui-data`).

## Step 2: Create the Space

1.  Go to [huggingface.co/new-space](https://huggingface.co/new-space).
2.  Name it (e.g., `hermes-webui`).
3.  Select **Docker** as the SDK.
4.  Choose the **Blank** template or **Dockerfile**.
5.  Set the Space to **Public** or **Private**.

## Step 3: Configure Secrets

In your Space settings:

1.  Go to **Settings** > **Variables and secrets**.
2.  Add a New Secret:
    *   **Name:** `HF_TOKEN`
    *   **Value:** Your Hugging Face User Access Token (with write permission).
3.  Add a New Secret:
    *   **Name:** `REPO_ID`
    *   **Value:** the Repository ID of the dataset you created in Step 1 (e.g., `username/hermes-webui-data`).

## Step 4: Upload Files

Upload the following files to your Space repository:

1.  `Dockerfile.hf` (Rename it to `Dockerfile` if uploading via the web interface).
2.  `run_hf.sh`.

## Persistence Details

The application uses the `huggingface_hub` library's `CommitScheduler` to sync the `/app/data` directory to your dataset every 5 minutes. This includes:

*   **Sessions:** Your chat history.
*   **Settings:** UI preferences and configurations.
*   **Workspaces:** Any files created in the default workspace.

When the Space restarts, it automatically downloads the latest files from your Dataset.
