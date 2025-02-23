#!/bin/bash

pip install -r requirements.txt

python -c "import nltk; nltk.download('vader_lexicon')"

celery -A server.celery worker -l info & uvicorn server:app --host 0.0.0.0 --port 8000
