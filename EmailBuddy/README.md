# EmailBuddy

EmailBuddy is an agentic AI email assistant built with Jac, a new programming language for creating intelligent agents. It transforms your inbox into a graph-based knowledge system, enabling semantic search, analysis, and RAG-powered navigation through your emails.

Key Features
- Summarization & Context Retrieval: Get concise summaries or ask questions about conversations
- Graph-Based Representation: Emails stored as relationships between people and emails
- Web-based Chat Interface: Easy to setup webpage

## Architecture

The system consists of:

- **Backend** (`backend/`): Jaseci-based agent system with `.jac` files
  - `server.jac`: Main API endpoints
  - `nodes.jac`: Graph node definitions (Person, EmailNode)
  - `rag.jac`: Vector embedding and retrieval logic
  - `tools.jac`: Helper walkers and LLM integrations
  - `prompts.jac`: System prompts for the agent
  - **Vector DB**: SQLite database storing email embeddings
- **Frontend** (`frontend/`): Simple HTML/CSS/JS chat interface

## Prerequisites

- Python 3.12+
- Virtual environment (recommended)
- An OpenAI API key (or configure a different LLM in `backend/tools.jac`)

## Installation

1. **Clone the repository** (if applicable):
   ```bash
   git clone <repository-url>
   cd EmailBuddy
   ```

2. **Create and activate a virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up OpenAI API key** (or your preferred LLM):
   - If using OpenAI, ensure your API key is set as an environment variable:
     ```bash
     export OPENAI_API_KEY="your-api-key-here"
     ```
   - To use a different LLM (like Ollama, Gemini, or Claude), modify the `glob llm` line in `backend/tools.jac`

5. **Set up sqlite-vec**
   - Download and install latest version of [sqlite-vec](https://github.com/asg017/sqlite-vec) and move your OS's correct file into `backend/`
      - WSL/Linux: vec0.so
      - Mac: vec0.dylib
      - Windows: vec0.dll
   - Replace all instances of the filename `vec0.so` in `backend/rag.jac` with the proper file you downloaded from above

## How to Run

### 1. Start the Jaseci Server

Navigate to the backend directory and start the Jaseci server:

```bash
cd backend
jac serve server.jac
```

The server will start on `http://localhost:8000`

### 2. Open the Frontend

In a separate terminal, open the frontend interface:

```bash
# From the project root
cd frontend
python -m http.server 8080
```

Or simply open `frontend/index.html` directly in your browser.

### 3. Upload and Query Emails

1. Click the "Upload Emails (json)" button
2. Upload a JSON file containing your emails in the following format:

    This format is how gmail allows you to export your emails...
   ```json
   [
     {
       "date": "2025-10-10T08:15:22+00:00",
       "from": "Sender Name <sender@example.com>",
       "to": "Recipient Name <recipient@example.com>",
       "subject": "Email Subject",
       "body": "Email body content..."
     }
   ]
   ```
3. Once uploaded, ask questions about your emails in natural language!

## Example Queries

- "What did John say about the budget?"
- "Summarize all emails from last week"
- "Show me emails related to project deadlines"
- "Who was involved in the marketing campaign discussion?"

## Configuration

### Provide Agent with user info

There is a [config file](backend/config.json) that you can add ANY specific information such as your name, email address, position, etc.

As long as it follows the basic "str" -> "str" format of the example options any fields are okay to be added.

These will be added to the system prompt of the agent for extra context when answering your questions. 

### Change the LLM Model

Edit `backend/tools.jac` and uncomment/modify the desired model:

```jac
# For Ollama:
glob llm = Model(model_name="ollama/llama3.2:latest", verbose=True);

# For Gemini:
glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=True);

# For OpenAI (default):
glob llm = Model(model_name="openai/gpt-5", verbose=True);
```

### API Configuration

The default API key in `backend/jaclens.jac` is `"123456"`. Change this for production use.

## Project Structure

```
EmailBuddy/
├── backend/
│   ├── server.jac          # Main server and API endpoints
│   ├── nodes.jac           # Graph node definitions
│   ├── tools.jac           # Helper functions and LLM integration
│   ├── rag.jac             # Vector database and embedding logic
│   ├── prompts.jac         # System prompts
│   ├── jaclens.jac         # Public API configuration
│   └── __jac_gen__/        # Generated Jaseci files (ignore)
├── frontend/
│   ├── index.html          # Main UI
│   ├── script.js           # Frontend logic
│   └── style.css           # Styling
├── requirements.txt        # Python dependencies
└── README.md              # This file
```

## Technologies Used

- **Jaseci**: Agentic AI framework
- **byllm**: LLM integration layer
- **Sentence Transformers**: Text embeddings
- **NumPy**: Numerical operations
- **SQLite**: Vector database
- **jQuery**: Frontend interactions

## Notes

- The `vectorDB.db` file is created automatically on first email upload
- Email UUIDs are generated deterministically for consistency
- The graph structure: `Person → EmailNode → Person` represents sender and recipient relationships