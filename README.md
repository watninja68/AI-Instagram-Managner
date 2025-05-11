# Instagram AI Responder & Webhook Manager

This project is a Python-based server designed to handle Instagram webhooks for direct messages (DMs) and comments. It uses sentiment analysis and a Large Language Model (LLM) – Google Gemini – to generate and send context-aware automated responses. The server also provides a simple web interface to view incoming webhook events in real-time.

## Features

* **Instagram Webhook Integration:** Handles `POST` requests from Meta for Instagram events.
* **Webhook Signature Verification:** Ensures incoming requests are genuinely from Meta.
* **DM & Comment Processing:** Parses and processes both direct messages and comments.
* **Sentiment Analysis:** Utilizes NLTK's VADER to determine the sentiment (positive/negative) of incoming messages and comments.
* **AI-Powered Responses for DMs:** Leverages Google Gemini to generate dynamic and context-aware replies to DMs based on sentiment and conversation history. Uses a `system_prompt.txt` for LLM guidance.
* **Automated Comment Replies:** Sends predefined responses to comments based on sentiment.
* **Asynchronous Task Handling:** Uses Celery for background processing of sending DMs and replies, allowing for delayed and non-blocking responses.
* **Conversation Management for DMs:** Groups incoming DMs by conversation and schedules a single, consolidated response after a short delay to avoid overwhelming users or the API.
* **Event & Log Storage:**
    * Stores received webhook events in a JSON file (`webhook_events.json`).
    * Maintains in-memory logs for recent webhook activity.
* **Real-time Event Viewer:** A simple HTML page (`static/index.html`) displays webhook events as they arrive, updated via Server-Sent Events (SSE).
* **Health & Monitoring:** Includes `/ping` and `/health` endpoints for server status and basic metrics.
* **Easy Configuration:** Uses environment variables for sensitive credentials and settings.
* **CI/CD Ready:** Includes a GitHub Actions workflow (`.github/workflows/main_testfinalvlast.yml`) for automated deployment to Azure Web Apps.

## Directory Structure

```

.
├── .github/ \<br\>
│   └── workflows/ \<br\>
│       └── main\_testfinalvlast.yml \<br\>
├── static/ \<br\>
│   └── index.html \<br\>
├── server.py \<br\>
├── requirements.txt \<br\>
├── startup.sh \<br\>
├── system\_prompt.txt \<br\>
└── webhook\_events.json \<br\>

````

## Tech Stack

* **Backend:** Python, FastAPI
* **WSGI Server:** Uvicorn
* **Task Queue:** Celery (with in-memory broker/backend for simplicity, configurable for Redis)
* **NLP:** NLTK (for Sentiment Analysis)
* **LLM:** Google Gemini API
* **API Interaction:** Requests
* **Real-time Updates:** Server-Sent Events (SSE) via `sse-starlette`
* **Environment Management:** `python-dotenv`
* **Frontend (Event Viewer):** HTML, JavaScript
* **Deployment:** GitHub Actions, Azure Web App

## Setup and Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```

2.  **Create and activate a virtual environment:**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Download NLTK VADER lexicon:**
    Run the following in a Python interpreter:
    ```python
    import nltk
    nltk.download('vader_lexicon')
    ```
    *(This step might be handled by `startup.sh` in some environments, but manual download ensures it's available.;))*

5.  **Set up Environment Variables:**
    Create a `.env` file in the root directory and add the following variables. **Important:** Replace placeholder values with your actual credentials.

    ```env
    APP_SECRET="your_meta_app_secret"
    VERIFY_TOKEN="your_custom_verify_token"
    GEMINI_API_KEY="your_google_gemini_api_key"
    INSTAGRAM_ACCESS_TOKEN="your_instagram_graph_api_access_token"
    INSTAGRAM_ACCOUNT_ID="your_instagram_account_id"

    # Optional: If using Redis for Celery in production
    # CELERY_BROKER_URL="redis://localhost:6379/0"
    # CELERY_RESULT_BACKEND="redis://localhost:6379/0"
    ```
    * `APP_SECRET`: Used by Meta to sign webhook requests.
    * `VERIFY_TOKEN`: A token you define, used during webhook setup with Meta.
    * `GEMINI_API_KEY`: Your API key for Google Gemini.
    * `INSTAGRAM_ACCESS_TOKEN`: Long-lived access token for the Instagram Graph API with necessary permissions (e.g., `instagram_manage_messages`, `instagram_manage_comments`).
    * `INSTAGRAM_ACCOUNT_ID`: The ID of the Instagram account the bot will operate as (used to prevent replying to its own comments/messages).

6.  **Update `system_prompt.txt`:**
    Modify `system_prompt.txt` to customize the persona and instructions for the AI assistant. Ensure the contact details (email, phone) are updated if you intend to use them.

## Usage

1.  **Start the Celery Worker:**
    Open a terminal, activate the virtual environment, and run:
    ```bash
    celery -A server.celery worker -l info
    ```
    *(The `startup.sh` script also attempts to start this in the background when deploying).*

2.  **Start the FastAPI Application:**
    Open another terminal, activate the virtual environment, and run:
    ```bash
    uvicorn server:app --host 0.0.0.0 --port 8000 --reload
    ```
    *(The `--reload` flag is for development. The `startup.sh` script runs it without `--reload` for production).*

3.  **Configure Instagram Webhooks:**
    * You'll need a public URL for your server (e.g., using ngrok during development, or your Azure Web App URL once deployed).
    * Go to your Meta Developer App dashboard.
    * Set up webhooks for Instagram, subscribing to `messages` and `comments` fields.
    * **Callback URL:** `https://your-public-url.com/webhook`
    * **Verify Token:** The value you set for `VERIFY_TOKEN` in your `.env` file.

4.  **Access the Webhook Event Viewer:**
    Open your browser and navigate to `http://localhost:8000/static/index.html` (or the equivalent public URL) to see incoming webhook events in real-time.

## API Endpoints

* `GET /ping`:
    * Description: Simple health check to confirm the server is running.
    * Response: `{"message": "Server is active"}`
* `GET /health`:
    * Description: Provides server health status, uptime, and basic system metrics (CPU, memory, disk usage).
    * Response: JSON object with health details.
* `GET /webhook`:
    * Description: Endpoint for Meta to verify the webhook subscription. Handles `hub.mode=subscribe`, `hub.verify_token`, and `hub.challenge` query parameters.
* `POST /webhook`:
    * Description: Main endpoint to receive webhook events from Meta (Instagram). Verifies signature, parses events, and triggers appropriate actions (DM processing, comment replies).
* `GET /webhook_events`:
    * Description: Retrieves a list of all webhook events stored in `webhook_events.json`.
    * Response: `{"events": [...]}`
* `GET /webhook_logs`:
    * Description: Retrieves recent in-memory webhook-related log entries.
    * Response: `{"webhook_logs": [...]}`
* `GET /events`:
    * Description: Server-Sent Events (SSE) endpoint that streams new webhook events to connected clients in real-time. Used by `static/index.html`.
* `GET /static/{path:path}`:
    * Description: Serves static files (e.g., `index.html`).

## How It Works

### Webhook Handling
1.  **Verification (`GET /webhook`):** Meta sends a GET request with a challenge token. The server verifies the `VERIFY_TOKEN` and returns the challenge.
2.  **Event Notification (`POST /webhook`):**
    * Meta sends a POST request with event data in JSON format.
    * The server verifies the `X-Hub-Signature-256` header using the `APP_SECRET`.
    * The `parse_instagram_webhook` function extracts relevant information (sender, message text, type, etc.).
3.  **Event Logging & SSE:** Valid events are logged, stored in `WEBHOOK_EVENTS` (and saved to `webhook_events.json`), and pushed to connected SSE clients.

### Direct Message (DM) Processing
1.  Incoming DMs (not echoes) are added to a `message_queue` grouped by `conversation_id` (a combination of sender and recipient IDs).
2.  A Celery task (`send_dm`) is scheduled with a random delay (1-2 minutes) when the *first* message of a conversation arrives.
3.  If more messages arrive for the *same* conversation *before* the initial task executes, the existing task is revoked, and a new `send_dm` task is scheduled with a shorter delay (e.g., 30 seconds). This bundles messages for a more natural conversational flow.
4.  The `send_dm` task:
    * Combines all messages in the queue for that conversation.
    * Performs sentiment analysis on the combined text.
    * Constructs a prompt for the Google Gemini LLM based on the `system_prompt.txt`, combined message text, and sentiment.
    * Calls the LLM to get a response. If the LLM fails, it falls back to default positive/negative DM responses.
    * Sends the generated (or default) response back to the user via the Instagram Graph API (`postmsg` function).
    * Clears the message queue for that conversation.

### Comment Processing
1.  Incoming comments (not from the bot's own `account_id`) are processed.
2.  Sentiment analysis is performed on the comment text.
3.  A predefined response (`default_comment_response_positive` or `default_comment_response_negative`) is selected based on the sentiment.
4.  A Celery task (`send_delayed_reply`) is scheduled with a random delay (1-2 minutes) to send the reply to the comment via the Instagram Graph API (`sendreply` function).

### Sentiment Analysis
The `analyze_sentiment` function uses NLTK's VADER (Valence Aware Dictionary and sEntiment Reasoner). It calculates a compound score; if greater than 0.25, it's considered "Positive," otherwise "Negative".

## Deployment

This project includes a GitHub Actions workflow (`.github/workflows/main_testfinalvlast.yml`) for continuous deployment to Azure Web Apps.

### Azure Web App Configuration:
* **Runtime:** Python (version specified in the workflow, e.g., 3.11).
* **Startup Command:** The `startup.sh` script is designed to be used as the startup command. Ensure it's executable (`chmod +x startup.sh`).
    ```bash
    ./startup.sh
    ```
    This script will:
    1.  Install Python dependencies.
    2.  (Attempt to) Download NLTK data.
    3.  Start the Celery worker in the background.
    4.  Start the Uvicorn server for the FastAPI application.
* **Application Settings (Environment Variables):** Configure the same environment variables (`APP_SECRET`, `VERIFY_TOKEN`, `GEMINI_API_KEY`, `INSTAGRAM_ACCESS_TOKEN`, `INSTAGRAM_ACCOUNT_ID`) in your Azure Web App's configuration settings.
* **HTTPS Only:** Ensure "HTTPS Only" is enabled for your Azure Web App, as Meta Webhooks require HTTPS callback URLs.

### GitHub Actions Workflow:
The workflow (`main_testfinalvlast.yml`) is triggered on pushes to the `main` branch or can be manually dispatched.
1.  **Build Job:**
    * Checks out the code.
    * Sets up the specified Python version.
    * Creates a virtual environment and installs dependencies.
    * Zips the application files into an artifact.
    * Uploads the artifact.
2.  **Deploy Job:**
    * Downloads the artifact from the build job.
    * Unzips the artifact.
    * Logs into Azure using service principal credentials stored as GitHub secrets.
    * Deploys the application to the specified Azure Web App and slot.

**Required GitHub Secrets for Azure Deployment:**
* `AZUREAPPSERVICE_CLIENTID_...`
* `AZUREAPPSERVICE_TENANTID_...`
* `AZUREAPPSERVICE_SUBSCRIPTIONID_...`

(The exact names of these secrets are defined in the `azure/login@v2` step of the workflow file.)

## Future Improvements / Considerations

* **More Sophisticated LLM Prompting:** Enhance `system_prompt.txt` and logic for more nuanced LLM responses.
* **Error Handling & Retries:** Implement more robust error handling for API calls and Celery tasks.
* **Scalable Celery Backend:** For production, replace the in-memory Celery broker/backend with Redis or RabbitMQ.
* **Database for Events/Logs:** For larger scale, store events and logs in a proper database instead of a JSON file and in-memory deque.
* **Rate Limiting:** Be mindful of Instagram API rate limits and implement strategies if necessary.
* **Testing:** Add unit and integration tests.
* **Security:** Regularly review and update dependencies. Further secure API keys and tokens.
* **UI Enhancements:** Improve the event viewer frontend with more features (filtering, search).
* **Intent Recognition:** Beyond sentiment, implement intent recognition for more complex conversational flows.
