#!/bin/bash

# If the webhook_events.json file doesn't exist in the writable folder, create it
if [ ! -f "$HOME/webhook_events.json" ]; then
    touch "$HOME/webhook_events.json"
fi

# Use chmod to ensure the file is writable
chmod 666 "$HOME/webhook_events.json"

# Create (or update) a symbolic link in the current directory pointing to the writable file
ln -sf "$HOME/webhook_events.json" webhook_events.json
pip install -r requirements.txt

python -c "import nltk; nltk.download('vader_lexicon')"

celery -A server.celery worker -l info & uvicorn server:app --host 0.0.0.0 --port 8000
