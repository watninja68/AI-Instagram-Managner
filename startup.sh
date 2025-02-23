#!/bin/bash
set -e
# Install required Python packages
pip install -r requirements.txt

# Download the NLTK vader lexicon (if not already downloaded)

# Start the Celery worker in the background
celery -A server.celery worker -l info &

# Start the Uvicorn server
uvicorn server:app --host 0.0.0.0 --port 8000