FROM python:3.12-slim

LABEL maintainer="nesquena"
LABEL description="Hermes Web UI — browser interface for Hermes Agent"

# Install system packages
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    rsync \
    git \
    sqlite3 \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# UTF-8
RUN apt-get update && apt-get install -y locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.utf8
ENV LC_ALL=C

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    PATH="/home/hermeswebui/.local/bin:$PATH"

WORKDIR /apptoo

# Create the unprivileged runtime user
RUN groupadd -g 1024 hermeswebui \
    && useradd -u 1024 -d /home/hermeswebui -g hermeswebui -G users -s /bin/bash -m hermeswebui \
    && mkdir -p /app /uv_cache \
    && chown -R hermeswebui:hermeswebui /home/hermeswebui /app /uv_cache

# Pre-install uv and hf tool
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && su hermeswebui -c "/usr/local/bin/uv tool install hf"

# Clone or Copy source code
RUN git clone https://github.com/nesquena/hermes-webui.git /apptoo

# Copy initialization script
COPY hermes-webui/docker_init.bash /hermeswebui_init.bash
RUN chmod 555 /hermeswebui_init.bash
RUN touch /.within_container

# Default to binding all interfaces
ENV HERMES_WEBUI_HOST=0.0.0.0
ENV HERMES_WEBUI_PORT=8787

EXPOSE 8787

USER root
CMD ["/hermeswebui_init.bash"]
