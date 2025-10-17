import sqlite3;
import sentence_transformers;
import numpy as np;
include nodes;


def cosine_similarity(a: np.narray, b: np.narray) -> float{
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b));
}
    
def create_email_embedding(jsonified_email: dict) -> None{
    conn: sqlite3.Connection = sqlite3.connect("vectorDB.db");
    cursor: sqlite3.Cursor = conn.cursor();

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        content TEXT NOT NULL,
        embedding BLOB
    )
    """);

    sender: str = jsonified_email["from"];        
    recipients: str = str(jsonified_email["to"]);
    date: str = jsonified_email["subject"];
    subject: str = jsonified_email["subject"];
    body: str = jsonified_email["subject"];

    model = sentence_transformers.SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2");
    email = f"date: <{date}>\nsender: <{sender}>\nrecipient: <{recipients}>\nsubject: <{subject}>\n\nbody:\n{body}";
    embeddings = model.encode([email])[0];
    embedding = np.array(embeddings, dtype=np.float32);
    embedding_blob = embedding.tobytes();

    cursor.execute("INSERT INTO emails (content, embedding) VALUES (?, ?)", (email, embedding_blob));
    conn.commit();
    conn.close();
}

def find_email_body(query: str, top_k: int=3) -> list[str] {
    conn: sqlite3.Connection = sqlite3.connect("vectorDB.db");
    cursor: sqlite3.Cursor  = conn.cursor();

    model = sentence_transformers.SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2");
    query_embedding = model.encode([query])[0];
    query_embedding = np.array(query_embedding, dtype=np.float32);

    cursor.execute("SELECT id, content, embedding FROM emails");
    rows = cursor.fetchall();

    results = [];

    for row in rows {
        row_id = row[0];
        content = row[1];
        embedding_blob = row[2];
        embedding = np.frombuffer(embedding_blob, dtype=np.float32);
        sim = cosine_similarity(query_embedding, embedding);
        results.append((row_id, content, sim));
    }
        
    conn.close();

    results.sort(key=lambda x: tuple: x[2], reverse=True);

    most_likely_emails: list = [result[1] for result in results];
    return most_likely_emails[:top_k];
}
