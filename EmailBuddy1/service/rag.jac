import os;
import sqlite3;
import numpy as np;
import from sentence_transformers { SentenceTransformer }
include service.nodes;

# Initialize the token and model inside a function
def init_model() -> SentenceTransformer {
    os.environ['HF_TOKEN'] = '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';
    os.environ['HUGGINGFACE_HUB_TOKEN'] = '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';
    
    # Use locally cached model (already downloaded)
    return SentenceTransformer(
        "sentence-transformers/all-MiniLM-L6-v2",
        local_files_only=True,
        trust_remote_code=False
    );
}

# Initialize the model
glob model = init_model();

def create_email_embedding(jsonified_email: dict, email_uuid: str) -> None {
    conn: sqlite3.Connection = sqlite3.connect("vectorDB.db");
    cursor: sqlite3.Cursor = conn.cursor();
    conn.enable_load_extension(True);
    conn.load_extension("service/vec0.so");

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        email_uuid TEXT NOT NULL,
        embedding VECTOR(384)
    )
    """);

    sender: str = jsonified_email["from"];        
    recipients: str = str(jsonified_email["to"]);
    date: str = jsonified_email["date"];
    subject: str = jsonified_email["subject"];
    body: str = jsonified_email["body"];

    email = f"date: <{date}>\nsender: <{sender}>\nrecipient: <{recipients}>\nsubject: <{subject}>\n\nbody:<{body}>";
    embeddings = model.encode([email])[0];
    embedding = np.array(embeddings, dtype=np.float32);
    
    cursor.execute(
        "INSERT INTO emails (content, email_uuid, embedding) VALUES (?, ?, ?)",
        (email, email_uuid, embedding.tobytes())
    );
    conn.commit();
    conn.close();
}

def find_emails(query: str, top_k: int = 10) -> list[tuple[str, str, float]] {
    conn: sqlite3.Connection = sqlite3.connect("vectorDB.db");
    cursor: sqlite3.Cursor  = conn.cursor();
    conn.enable_load_extension(True);
    conn.load_extension("service/vec0.so");

    query_embedding = model.encode([query])[0].tobytes();

    cursor.execute("""
        SELECT email_uuid, content, vec_distance_cosine(embedding, ?) AS score
        FROM emails
        ORDER BY score ASC
        LIMIT ?
    """, (query_embedding, top_k));

    rows = cursor.fetchall();
    conn.close();


    return [(row[0], row[1], row[2]) for row in rows];
}
