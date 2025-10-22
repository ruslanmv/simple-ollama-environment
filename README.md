<div align="center">
  <a href="https://www.python.org" target="_blank"><img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/python/python-original.svg" alt="Python" width="60" height="60"/></a>
  <a href="https://www.docker.com/" target="_blank"><img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/docker/docker-original-wordmark.svg" alt="Docker" width="60" height="60"/></a>
  <a href="https://jupyter.org/" target="_blank"><img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/jupyter/jupyter-original-wordmark.svg" alt="Jupyter" width="60" height="60"/></a>
</div>

# Simple Ollama Environment — Reproducible Python 3.11 + Jupyter + LLM

This repository provides a minimal, reproducible Python **3.11** environment with **Jupyter Notebook** and **Ollama** integration. You can run locally (virtualenv) or in a **single Docker container** that comes with **Ollama preinstalled** so you can chat with an LLM from a notebook immediately.

<p align="center">
  <img alt="Python Version" src="https://img.shields.io/badge/python-3.11-blue.svg">
  <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-blue.svg">
  <img alt="Docker" src="https://img.shields.io/badge/docker-ready-blue.svg?logo=docker">
</p>

---

## What You Get

- **Two Workflows**: local virtual environment or a fully containerized setup.
- **Ollama-ready**: install the **host** Ollama with `make install` (best-effort), or use the **Docker** image that already bundles Ollama.
- **Jupyter-ready**: `make install` registers a kernel named **Python 3.11 (simple-env)**.
- **Automation**: a cross-platform `Makefile` (Windows/macOS/Linux) manages everything.

![](assets/2025-10-13-18-55-21.png)

---

## 🚀 Quick Starts

### Option A — Docker (Recommended)

1) **Build the image** (Ollama + Python + Jupyter + project):
```bash
make build-container
```

2) **Run it** (Jupyter on :8888, Ollama API on :11434):
```bash
make run-container
```

3) Open **http://localhost:8888** and run **`notebooks/ollama_quickstart.ipynb`**.

> The image pre-pulls a tiny model (`qwen2.5:0.5b-instruct`) during build.  
> To change which models are baked in:  
> `docker build -t simple-env:latest --build-arg PREPULL="llama3.2:1b" .`

---

### Option B — Local (Virtualenv + Host Ollama)

1) Install everything (Python deps + Jupyter kernel + **host Ollama** best-effort):
```bash
make install
```

2) Start **Jupyter Notebook**:
```bash
jupyter notebook
```
Choose kernel **Python 3.11 (simple-env)** and open `notebooks/ollama_quickstart.ipynb`.

3) Ensure Ollama is installed and running on your machine (background service). If needed:
```bash
make install-ollama     # attempts OS-specific install
ollama pull qwen2.5:0.5b-instruct
```

---

## 🧪 Example Inference (from the notebook)

Open **`notebooks/ollama_quickstart.ipynb`** and run the cells. It will:
- ensure the Python client `ollama` is importable,
- **pull** `qwen2.5:0.5b-instruct` (first run only),
- run a **chat** call and print the response.

The Python client talks to **http://localhost:11434**.

---

## Customization

- Add Python libraries by editing `pyproject.toml` and then re-run `make install` (local) or `make build-container` (Docker).
- To keep memory low on small laptops, stick to tiny models (e.g., `qwen2.5:0.5b-instruct`, `qwen2.5-coder:0.5b-instruct`, `llama3.2:1b`).

---

## Project Configuration Files

<details>
<summary><strong>pyproject.toml</strong></summary>

```toml
[build-system]
requires = ["setuptools>=64", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "simple-environment"
version = "0.2.0"
description = "Minimal environment for Jupyter Notebook (Python 3.11) with Ollama client."
requires-python = ">=3.11,<3.12"
dependencies = [
  "notebook",
  "ipykernel",
  "ollama",
]

[tool.setuptools]
packages = []
```
</details>

<details>
<summary><strong>Dockerfile</strong> (Ollama + Jupyter)</summary>

```dockerfile
# syntax=docker/dockerfile:1
FROM ollama/ollama:latest
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MAX_LOADED_MODELS=1 \
    OLLAMA_NUM_PARALLEL=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip build-essential ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/app
COPY . .
RUN python3 -m pip install --upgrade pip && pip install .
ARG PREPULL="qwen2.5:0.5b-instruct"
RUN bash -lc 'set -e; ollama serve & pid=$!; \
  for i in $(seq 1 60); do curl -fsS http://127.0.0.1:11434/api/tags >/dev/null && break || sleep 0.5; done; \
  for m in $PREPULL; do echo "Pulling $m"; ollama pull "$m" || true; done; \
  kill $pid || true; wait $pid || true'
WORKDIR /workspace
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
EXPOSE 8888 11434
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```
</details>


## Quickstart

To run and chat with a small model:

```shell
ollama run qwen2.5:0.5b-instruct
```

Or Llama 3.2 (1B variant):

```shell
ollama run llama3.2:1b
```

## Model library

Ollama supports many models in the online library.

Examples:

| Model            | Parameters | Size  | Download                     |
| ---------------- | ---------- | ----- | ---------------------------- |
| Gemma 3          | 1B         | 815MB | `ollama run gemma3:1b`       |
| Gemma 3          | 4B         | 3.3GB | `ollama run gemma3`          |
| Llama 3.2        | 1B         | 1.3GB | `ollama run llama3.2:1b`     |
| Llama 3.2        | 3B         | 2.0GB | `ollama run llama3.2`        |
| Llama 3.2 Vision | 11B        | 7.9GB | `ollama run llama3.2-vision` |
| Phi 4 Mini       | 3.8B       | 2.5GB | `ollama run phi4-mini`       |
| Mistral          | 7B         | 4.1GB | `ollama run mistral`         |
| Moondream 2      | 1.4B       | 829MB | `ollama run moondream`       |

> **Guidance:** ~8 GB free RAM for 7B; ~16 GB for 13B; ~32 GB for 33B. On 8 GB laptops, stick to 0.5B–1B models for best experience.


---

## OS-Specific Notes (Local)

- **Windows**: `make` works best in **Git Bash**. The `Makefile` invokes `winget install Ollama.Ollama` if `ollama` is missing (you can also use the GUI installer from https://ollama.com/download).
- **macOS**: `brew install --cask ollama` installs the app/service.
- **Linux**: `curl -fsSL https://ollama.com/install.sh | sh` installs the service.

---

## Troubleshooting

- **`ollama pull` fails in notebook**: Make sure the Ollama server is reachable at `http://localhost:11434` (it starts automatically in the Docker image). On local machines, launch the Ollama app/service first.
- **Jupyter kernel missing**: Re-run `make notebook`.
- **Ports in use**: Change exposed ports via `DOCKER_PORT` and `DOCKER_PORT_OLLAMA` variables in the Makefile.

---

Happy hacking! 🚀
