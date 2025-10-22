# syntax=docker/dockerfile:1
# Container with Ollama preinstalled + Python + Jupyter + this project
FROM ollama/ollama:latest

# Env for Python & Ollama
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MAX_LOADED_MODELS=1 \
    OLLAMA_NUM_PARALLEL=1 \
    # Runtime models to pull (space-separated list)
    OLLAMA_PREPULL="qwen2.5:0.5b-instruct" \
    # Put our venv on PATH for all processes
    PATH="/opt/venv/bin:${PATH}"

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip build-essential ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*

# ---------- Python: create a venv to avoid PEP 668 ----------
# NOTE: do NOT install to the system interpreter; install inside /opt/venv.
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/python -m pip install --no-cache-dir --upgrade pip

# App install context
WORKDIR /opt/app
COPY . .

# Install your project (from pyproject.toml) INTO the venv
RUN /opt/venv/bin/pip install --no-cache-dir .

# ---------- Pre-pull models during build (optional) ----------
# Override with: --build-arg PREPULL="llama3.2:1b mistral"
ARG PREPULL="qwen2.5:0.5b-instruct"
RUN bash -lc 'set -euo pipefail; \
  echo "Starting temporary Ollama daemon to pre-pull models: $PREPULL"; \
  ollama serve & pid=$!; \
  for i in $(seq 1 60); do \
    if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null; then break; fi; \
    sleep 0.5; \
  done; \
  for m in $PREPULL; do \
    echo "Pulling $m..."; \
    ollama pull "$m" || true; \
  done; \
  kill $pid || true; \
  wait $pid 2>/dev/null || true'

# Working directory for notebooks / user files
WORKDIR /workspace

# Entrypoint to start Ollama + Jupyter
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8888 11434

# Healthcheck (will pass after entrypoint starts the daemon)
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=10 \
  CMD curl -fsS http://127.0.0.1:11434/api/tags || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
