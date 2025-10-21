# syntax=docker/dockerfile:1
# Container with Ollama preinstalled + Python + Jupyter + this project
FROM ollama/ollama:latest

# Set environment variables for Python & Ollama
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MAX_LOADED_MODELS=1 \
    OLLAMA_NUM_PARALLEL=1

# Install Python 3.11 and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip build-essential ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*

# Set the working directory for the application installation
WORKDIR /opt/app

# Copy the entire project context into the image
COPY . .

# Install Python dependencies from your pyproject.toml
RUN python3 -m pip install --upgrade pip \
 && pip install .

# Pre-pull a small model during build (optional). Override with --build-arg PREPULL="..."
ARG PREPULL="qwen2.5:0.5b-instruct"
RUN bash -lc 'set -e; \
  ollama serve & pid=$!; \
  for i in $(seq 1 60); do curl -fsS http://127.0.0.1:11434/api/tags >/dev/null && break || sleep 0.5; done; \
  for m in $PREPULL; do echo "Pulling $m"; ollama pull "$m" || true; done; \
  kill $pid || true; wait $pid || true'

# Set the default working directory for the user
WORKDIR /workspace

# Copy entrypoint to start both Ollama and Jupyter
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8888 11434

# Run both servers (Ollama + Jupyter Notebook)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
