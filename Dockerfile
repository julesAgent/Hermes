FROM ghcr.io/nesquena/hermes-webui:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN git clone --depth=1 https://github.com/NousResearch/hermes-agent.git /opt/hermes \
    && mkdir -p /data/.hermes /data/.hermes/webui-mvp /data/.hermes/agent /workspace \
    && rm -rf /home/hermeswebui/.hermes \
    && ln -s /data/.hermes /home/hermeswebui/.hermes \
    && chown -R hermeswebui:hermeswebui /data /workspace /opt/hermes \
    && chown -h hermeswebui:hermeswebui /home/hermeswebui/.hermes
ENV HERMES_HOME=/home/hermeswebui/.hermes \
    HERMES_CONFIG_PATH=/home/hermeswebui/.hermes/config.yaml \
    HERMES_WEBUI_STATE_DIR=/home/hermeswebui/.hermes/webui-mvp \
    HERMES_WEBUI_DEFAULT_WORKSPACE=/workspace \
    HERMES_WEBUI_AGENT_DIR=/home/hermeswebui/.hermes/agent \
    HERMES_WEBUI_HOST=0.0.0.0 \
    HERMES_WEBUI_PORT=8787 \
    HERMES_EXEC_ASK=1 \
    WANTED_UID=1024 \
    WANTED_GID=1024

EXPOSE 8787

CMD ["/hermeswebui_init.bash"]
