#!/usr/bin/env bash
set -euo pipefail

# Ensure the venv is on PATH for this process (so 'jupyter' is found)
export PATH="/opt/venv/bin:${PATH}"

# Start Ollama server in the background
ollama serve &
OLLAMA_PID=$!

# Wait for the Ollama API to be ready
for i in {1..60}; do
  if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null; then
    break
  fi
  sleep 0.5
done

# Pre-pull models at runtime (defaults to qwen2.5:0.5b-instruct)
# Override with: docker run -e OLLAMA_PREPULL="llama3.2:1b mistral"
if [ -n "${OLLAMA_PREPULL:-}" ]; then
  echo "Runtime prepull: ${OLLAMA_PREPULL}"
  for m in ${OLLAMA_PREPULL}; do
    echo "Prepulling $m"
    ollama pull "$m" || true
  done
fi

# Launch Jupyter Notebook in the foreground (no token)
exec jupyter notebook --ip=0.0.0.0 --no-browser --allow-root --NotebookApp.token=
