#!/usr/bin/env bash
set -euo pipefail

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

# Optionally pull more models at runtime (space-separated list)
if [ -n "${OLLAMA_PREPULL:-}" ]; then
  for m in ${OLLAMA_PREPULL}; do
    echo "Prepulling $m"
    ollama pull "$m" || true
  done
fi

# Launch Jupyter Notebook in the foreground (no token)
exec jupyter notebook --ip=0.0.0.0 --no-browser --allow-root --NotebookApp.token=
