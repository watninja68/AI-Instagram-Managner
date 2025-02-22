#!/bin/bash

# Install dependencies
pip install -r requirements.txt

# Download NLTK data
python -c "import nltk; nltk.download('vader_lexicon')"

# Start both Celery worker and FastAPI application
celery -A server.celery worker -l info & uvicorn server:app --host 0.0.0.0 --port 8000
