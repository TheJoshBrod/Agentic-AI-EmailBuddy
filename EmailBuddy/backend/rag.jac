import sqlite3;
import sentence_transformers;
import numpy as np;
include nodes;

model = sentence_transformers.SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2");

def cosine_similarity(a: np.narray, b: np.narray) -> float{
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b));
}
    
def create_email_embedding(jsonified_email: dict, email_uuid: str) -> None{
    conn: sqlite3.Connection = sqlite3.connect("vectorDB.db");
    cursor: sqlite3.Cursor = conn.cursor();

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        email_uuid TEXT NOT NULL,
        embedding BLOB
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
    embedding_blob = embedding.tobytes();

    cursor.execute("INSERT INTO emails (content, email_uuid, embedding) VALUES (?, ?, ?)", (email, email_uuid, embedding_blob));
    conn.commit();
    conn.close();
}

def find_emails(query: str, top_k: int=10) -> list[tuple[str, str, float]]: {
    conn: sqlite3.Connection = sqlite3.connect("vectorDB.db");
    cursor: sqlite3.Cursor  = conn.cursor();

    query_embedding = model.encode([query])[0];
    query_embedding = np.array(query_embedding, dtype=np.float32);

    cursor.execute("SELECT email_uuid, content, embedding FROM emails");
    rows = cursor.fetchall();

    results = [];

    for row in rows {
        email_uuid = row[0];
        content = row[1];
        embedding_blob = row[2];
        embedding = np.frombuffer(embedding_blob, dtype=np.float32);
        sim = cosine_similarity(query_embedding, embedding);
        results.append((email_uuid, content, sim));
    }

    conn.close();

    results.sort(key=lambda x: tuple: x[2], reverse=True);

    results.sort(key=lambda x: x[2], reverse=True);
    return results[:top_k];
}
