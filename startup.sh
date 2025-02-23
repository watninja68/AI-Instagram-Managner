#!/bin/bash
set -e

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

# Start the Uvicorn server
uvicorn server:app --host 0.0.0.0 --port 8000
