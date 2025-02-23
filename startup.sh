#!/bin/bash
set -e

# Check if redis-server is installed; if not, install it.
if ! command -v redis-server >/dev/null 2>&1; then
    apt-get install -y redis-server
else
    echo "redis-server is already installed."
fi

# Start Redis server in the background if it's not already running
if ! pgrep redis-server > /dev/null; then
    echo "Starting Redis server..."
    redis-server --daemonize yes
    sleep 2  # Allow Redis time to initialize
else
    echo "Redis server is already running."
fi

# Ensure webhook_events.json exists in the HOME directory and is writable
if [ ! -f "$HOME/webhook_events.json" ]; then
    touch "$HOME/webhook_events.json"
fi

chmod 666 "$HOME/webhook_events.json"
ln -sf "$HOME/webhook_events.json" webhook_events.json

# Install required Python packages
pip install -r requirements.txt

# Download the NLTK vader lexicon (if not already downloaded)
python -c "import nltk; nltk.download('vader_lexicon')"

# Start the Celery worker in the background
celery -A server.celery worker -l info &

# Start the Uvicorn server for FastAPI
uvicorn server:app --host 0.0.0.0 --port 8000
