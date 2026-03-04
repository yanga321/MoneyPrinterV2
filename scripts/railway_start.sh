#!/usr/bin/env bash
set -euo pipefail

echo "[railway] Starting MoneyPrinterV2 deployment..."

# ---- Step 1: Generate config.json from environment variables ----
python /app/scripts/generate_config.py
echo "[railway] Generated config.json from environment variables."

# ---- Step 2: Ensure .mp directory structure ----
mkdir -p /app/.mp

# ---- Step 3: Persist Ollama models on the volume to avoid re-downloading ----
mkdir -p /app/.mp/ollama-models
export OLLAMA_MODELS=/app/.mp/ollama-models

# ---- Step 4: Start Ollama server in background ----
echo "[railway] Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready (up to 60 seconds)
for i in $(seq 1 60); do
    if curl -sf http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
        echo "[railway] Ollama is ready."
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "[railway] ERROR: Ollama failed to start within 60 seconds."
        exit 1
    fi
    sleep 1
done

# ---- Step 5: Pull the configured model ----
MODEL="${OLLAMA_MODEL:-llama3.2:3b}"
echo "[railway] Pulling Ollama model: ${MODEL}..."
ollama pull "$MODEL"
echo "[railway] Model ${MODEL} is ready."

# ---- Step 6: Seed account data if not present ----
if [ -f /app/railway/seed-data/youtube.json ] && [ ! -f /app/.mp/youtube.json ]; then
    cp /app/railway/seed-data/youtube.json /app/.mp/youtube.json
    echo "[railway] Seeded youtube.json"
fi
if [ -f /app/railway/seed-data/twitter.json ] && [ ! -f /app/.mp/twitter.json ]; then
    cp /app/railway/seed-data/twitter.json /app/.mp/twitter.json
    echo "[railway] Seeded twitter.json"
fi

# ---- Step 7: Launch the scheduler ----
echo "[railway] Starting scheduler..."
exec python /app/src/railway_scheduler.py
