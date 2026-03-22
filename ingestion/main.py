import hashlib
import json
import os
from datetime import datetime, timezone

from google.cloud import storage
import psycopg
from pgvector.psycopg import register_vector
import vertexai
from vertexai.language_models import TextEmbeddingInput, TextEmbeddingModel


GCS_BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
GCS_PREFIX = os.getenv("GCS_PREFIX", "raw/")
DB_NAME = os.getenv("DB_NAME", "chatbot_db")
DB_USER = os.getenv("DB_USER", "bff_user")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "text-embedding-005")
PROJECT_ID = os.getenv("PROJECT_ID")
VERTEX_REGION = os.getenv("VERTEX_REGION", "asia-east1")
MAX_BLOBS = int(os.getenv("MAX_BLOBS", "20"))
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", "1200"))
CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP", "150"))


def validate_env():
    required = {
        "GCS_BUCKET_NAME": GCS_BUCKET_NAME,
        "DB_PASSWORD": DB_PASSWORD,
        "DB_HOST": DB_HOST,
        "PROJECT_ID": PROJECT_ID,
    }
    missing = [k for k, v in required.items() if not v]
    if missing:
        raise ValueError(f"Missing required env vars: {', '.join(missing)}")


def utcnow_iso():
    return datetime.now(timezone.utc).isoformat()


def normalize_text(record):
    parts = [
        f"Category: {record.get('category', '')}",
        f"Title: {record.get('title', '')}",
        f"Description: {record.get('description', '')}",
        f"HowToPrevent: {record.get('how_to_prevent', '')}",
        f"ExampleScenarios: {record.get('example_scenarios', '')}",
        f"Background: {record.get('background', '')}",
    ]
    return "\n\n".join(p for p in parts if p.strip())


def make_hash(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def chunk_text(text, size, overlap):
    if len(text) <= size:
        return [text]

    chunks = []
    step = max(1, size - overlap)
    idx = 0
    while idx < len(text):
        chunk = text[idx : idx + size]
        if chunk.strip():
            chunks.append(chunk)
        if idx + size >= len(text):
            break
        idx += step
    return chunks


# [設計假設] 向量資料庫（Cloud SQL instance）預期會隨 make down 被摧毀，make up 重建後再 reindex。
# 因此 init_db 只需 CREATE TABLE IF NOT EXISTS，不需要處理欄位更新邏輯。
# 若未來轉為長期維護模式（不砍 instance），需改用 ALTER TABLE ADD COLUMN IF NOT EXISTS 補欄位。
def init_db(conn):
    with conn.cursor() as cur:
        cur.execute("CREATE EXTENSION IF NOT EXISTS vector")
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS documents (
                id BIGSERIAL PRIMARY KEY,
                source_file TEXT NOT NULL,
                category TEXT,
                title TEXT,
                detail_url TEXT,
                doc_hash TEXT UNIQUE NOT NULL,
                scraped_at TIMESTAMPTZ,
                ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
            """
        )
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS chunks (
                id BIGSERIAL PRIMARY KEY,
                document_id BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                chunk_index INT NOT NULL,
                chunk_text TEXT NOT NULL,
                chunk_hash TEXT UNIQUE NOT NULL,
                token_count INT,
                category TEXT,
                stack TEXT
            )
            """
        )
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS chunk_embeddings (
                chunk_id BIGINT PRIMARY KEY REFERENCES chunks(id) ON DELETE CASCADE,
                embedding vector(768) NOT NULL,
                model TEXT NOT NULL,
                embedded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
            """
        )
        cur.execute("CREATE INDEX IF NOT EXISTS idx_documents_doc_hash ON documents(doc_hash)")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_chunks_chunk_hash ON chunks(chunk_hash)")
    conn.commit()


def get_db_conn():
    conn = psycopg.connect(
        host=DB_HOST,
        port=int(DB_PORT),
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )
    return conn


def get_embedding_model():
    vertexai.init(project=PROJECT_ID, location=VERTEX_REGION)
    return TextEmbeddingModel.from_pretrained(EMBEDDING_MODEL)


def embed_text(model, text):
    embedding_input = TextEmbeddingInput(task_type="RETRIEVAL_DOCUMENT", text=text)
    embedding = model.get_embeddings([embedding_input], output_dimensionality=768)[0].values
    return embedding


def fetch_blobs():
    client = storage.Client()
    blobs = list(client.list_blobs(GCS_BUCKET_NAME, prefix=GCS_PREFIX))
    blobs = [b for b in blobs if b.name.endswith(".json")]
    blobs.sort(key=lambda b: b.updated or datetime.min.replace(tzinfo=timezone.utc), reverse=True)
    return blobs[:MAX_BLOBS]


def load_records_from_blob(blob):
    payload = blob.download_as_text(encoding="utf-8")
    data = json.loads(payload)
    if isinstance(data, list):
        return data
    return []


# [Stack 分類策略] 目前使用 rule-based 關鍵字比對來標記 frontend/backend/both。
# 優點：快、免費、可控。缺點：關鍵字清單需手動維護，邊界案例判斷較弱。
# 若分類效果不佳，可改用 LLM（如 Gemini）進行語意分類，但每筆 chunk 多一次 API 呼叫，費用較高。
# 當前知識量小（A01-A10，約數十個 chunks），LLM 成本影響不大，可視品質需求決定是否升級。
FRONTEND_KEYWORDS = [
    "javascript", "browser", "dom", "html", "react", "angular", "vue",
    "csrf token", "csp", "content security policy", "cookie", "xss",
    "client-side", "client side", "front-end", "frontend",
]
BACKEND_KEYWORDS = [
    "server", "api", "sql", "database", "injection", "authentication",
    "session", "jwt", "python", "java", "node", "back-end", "backend",
    "query", "parameterized", "stored procedure", "orm",
]


def classify_stack(text: str) -> str:
    t = text.lower()
    is_fe = any(kw in t for kw in FRONTEND_KEYWORDS)
    is_be = any(kw in t for kw in BACKEND_KEYWORDS)
    if is_fe and is_be:
        return "both"
    if is_fe:
        return "frontend"
    if is_be:
        return "backend"
    return "both"  # 預設：無明確關鍵字時視為兩者皆適用


def upsert_document(cur, record, source_file, doc_hash):
    scraped_at = record.get("scraped_at")
    cur.execute(
        """
        INSERT INTO documents (source_file, category, title, detail_url, doc_hash, scraped_at, ingested_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (doc_hash) DO NOTHING
        RETURNING id
        """,
        (
            source_file,
            record.get("category"),
            record.get("title"),
            record.get("detail_url"),
            doc_hash,
            scraped_at,
            utcnow_iso(),
        ),
    )
    row = cur.fetchone()
    if row:
        return row[0], True

    cur.execute("SELECT id FROM documents WHERE doc_hash = %s", (doc_hash,))
    return cur.fetchone()[0], False


def upsert_chunk(cur, document_id, chunk_index, text, chunk_hash, category, stack):
    cur.execute(
        """
        INSERT INTO chunks (document_id, chunk_index, chunk_text, chunk_hash, token_count, category, stack)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (chunk_hash) DO NOTHING
        RETURNING id
        """,
        (document_id, chunk_index, text, chunk_hash, max(1, len(text) // 4), category, stack),
    )
    row = cur.fetchone()
    if row:
        return row[0], True

    cur.execute("SELECT id FROM chunks WHERE chunk_hash = %s", (chunk_hash,))
    return cur.fetchone()[0], False


def upsert_embedding(cur, chunk_id, embedding):
    cur.execute("SELECT 1 FROM chunk_embeddings WHERE chunk_id = %s", (chunk_id,))
    if cur.fetchone():
        return False

    cur.execute(
        """
        INSERT INTO chunk_embeddings (chunk_id, embedding, model, embedded_at)
        VALUES (%s, %s, %s, %s)
        """,
        (chunk_id, embedding, EMBEDDING_MODEL, utcnow_iso()),
    )
    return True


def run_ingestion():
    validate_env()

    blobs = fetch_blobs()
    if not blobs:
        print("[INFO] No raw JSON blobs found.")
        return

    model = get_embedding_model()
    stats = {
        "blobs": 0,
        "records": 0,
        "new_documents": 0,
        "new_chunks": 0,
        "new_embeddings": 0,
        "skipped_documents": 0,
    }

    with get_db_conn() as conn:
        init_db(conn)
        register_vector(conn)

        for blob in blobs:
            stats["blobs"] += 1
            records = load_records_from_blob(blob)
            print(f"[INFO] Processing {blob.name} with {len(records)} records")

            with conn.cursor() as cur:
                for record in records:
                    stats["records"] += 1
                    full_text = normalize_text(record)
                    doc_hash = make_hash(
                        f"{record.get('category', '')}|{record.get('title', '')}|{full_text}"
                    )

                    document_id, is_new_doc = upsert_document(cur, record, blob.name, doc_hash)
                    if is_new_doc:
                        stats["new_documents"] += 1
                    else:
                        stats["skipped_documents"] += 1

                    for idx, chunk in enumerate(chunk_text(full_text, CHUNK_SIZE, CHUNK_OVERLAP)):
                        chunk_hash = make_hash(f"{doc_hash}|{idx}|{chunk}")
                        category = record.get("category")
                        stack = classify_stack(chunk)
                        chunk_id, is_new_chunk = upsert_chunk(cur, document_id, idx, chunk, chunk_hash, category, stack)
                        if is_new_chunk:
                            stats["new_chunks"] += 1

                        if is_new_chunk:
                            emb = embed_text(model, chunk)
                            if upsert_embedding(cur, chunk_id, emb):
                                stats["new_embeddings"] += 1

                conn.commit()

    print("[INFO] Ingestion done")
    print(json.dumps(stats, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    run_ingestion()
