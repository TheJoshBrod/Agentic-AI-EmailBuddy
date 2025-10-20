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
        content TEXT NOT NULL,
        embedding BLOB
    )
    """);

    sender: str = jsonified_email["from"];        
    recipients: str = str(jsonified_email["to"]);
    date: str = jsonified_email["date"];
    subject: str = jsonified_email["subject"];
    body: str = jsonified_email["body"];

    model = sentence_transformers.SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2");
    email = f"date: <{date}>\nsender: <{sender}>\nrecipient: <{recipients}>\nsubject: <{subject}>\n\nbody:<{body}>";
    embeddings = model.encode([email])[0];
    embedding = np.array(embeddings, dtype=np.float32);
    embedding_blob = embedding.tobytes();

    cursor.execute("INSERT INTO emails (content, embedding) VALUES (?, ?)", (body, embedding_blob));
    conn.commit();
    conn.close();
}

def pick_best_email(emails: list[Email], target_text: str) -> Email{
    best: Email = None;
    score: float = 0.0;
    model = sentence_transformers.SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2");
    target_vector = np.array(model.encode([target_text])[0], dtype=np.float32);
    email_vectors = np.array(model.encode([email_node_to_string(email) for email in emails]), dtype=np.float32);

    for i in range(len(emails)) {
        sim = cosine_similarity(target_vector, email_vectors[i]);
        if sim > score {
            best = emails[i];
            score = sim;
        }
    }

    return best;
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
