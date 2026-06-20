import json
import os
import re
import uuid

import google.auth
import google.auth.transport.requests
import httpx
import websockets
import firebase_admin
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth

# ─── 環境變數 ────────────────────────────────────────────────────────────────

FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")
CES_APP_NAME = os.getenv("CES_APP_NAME")          # projects/.../apps/...
CES_DEPLOYMENT_NAME = os.getenv("CES_DEPLOYMENT_NAME")  # projects/.../deployments/...
# 多個 origin 以逗號分隔，例如：http://localhost:5500,https://client-xxx-uc.a.run.app
ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS", "http://localhost:5500,http://localhost:8000"
).split(",")

# 公司帳號規則：八碼員編 + @cathaybk.com.tw 或 @lab.cathaybkdev.com.tw
_COMPANY_EMAIL_RE = re.compile(r"^\d{8}@(cathaybk\.com\.tw|lab\.cathaybkdev\.com\.tw)$")

# Demo 用稱呼對照表：employee_id → display_name
_DISPLAY_NAME_MAP: dict[str, str] = {
    "00000001": "jojo",
    "q9898989": "jojo-私人",
}
_DEFAULT_DISPLAY_NAME = "John Doe"

# 開發用白名單：以逗號分隔的 email，例如 ALLOWED_EMAILS=you@gmail.com
# 生產環境（Cloud Run）保持空值，只走公司 domain 規則
_ALLOWED_EMAILS: set[str] = {
    e.strip().lower()
    for e in os.getenv("ALLOWED_EMAILS", "you@example.com").split(",")
    if e.strip()
}


def _validate_env():
    if not FIREBASE_PROJECT_ID:
        raise RuntimeError("Missing required env var: FIREBASE_PROJECT_ID")


# ─── CX Agent Studio 輔助 ──────────────────────────────────────────────────

def _get_ces_token() -> str:
    """取得 GCP ADC access token，用於呼叫 CES API。"""
    credentials, _ = google.auth.default(
        scopes=["https://www.googleapis.com/auth/cloud-platform"]
    )
    credentials.refresh(google.auth.transport.requests.Request())
    return credentials.token


# ─── Firebase Admin SDK 初始化 ───────────────────────────────────────────────
# 在 Cloud Run 上透過 chatbot-bff-sa 的 ADC 自動授權；本地開發需先執行：
#   gcloud auth application-default login
# verify_id_token() 本身只需 projectId 與公開金鑰 HTTPS 存取，不需 SA key 檔。

def _init_firebase():
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={"projectId": FIREBASE_PROJECT_ID})


# ─── FastAPI 應用 ────────────────────────────────────────────────────────────

_validate_env()
_init_firebase()

app = FastAPI(title="Bank AI BFF", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

_bearer = HTTPBearer()


# ─── 驗證中介層 ──────────────────────────────────────────────────────────────

async def verify_token(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
) -> dict:
    """
    1. 解碼並驗證 Firebase ID Token
    2. 確認 email 已驗證
    3. 確認符合公司帳號規則：^\d{8}@cathaybk\.com\.tw$
    """
    token = credentials.credentials
    try:
        claims = auth.verify_id_token(token)
    except auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Token expired")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    if not claims.get("email_verified", False):
        raise HTTPException(status_code=403, detail="Email not verified")

    email: str = claims.get("email", "").lower()
    if email not in _ALLOWED_EMAILS and not _COMPANY_EMAIL_RE.match(email):
        raise HTTPException(status_code=403, detail="Unauthorized account")

    return claims


# ─── Endpoints ───────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    """系統健康檢查，不需認證。"""
    return {"status": "ok"}


# session_id 只允許 URL-safe 字元，防止 path injection
_SESSION_ID_RE = re.compile(r'^[\w\-]{1,128}$')


@app.post("/query")
async def query(body: dict, claims: dict = Depends(verify_token)):
    """接受使用者問題，呼叫 CX Agent Studio runSession，回傳 AI 回答。"""
    if not CES_APP_NAME or not CES_DEPLOYMENT_NAME:
        raise HTTPException(status_code=503, detail="Agent not configured")

    question = body.get("question", "").strip()
    if not question:
        raise HTTPException(status_code=400, detail="question is required")

    # session_id 由 Client 維護以實現多輪對話；未提供時退回 BFF 產生（相容舊行為）
    raw_session_id = body.get("session_id", "").strip()
    if raw_session_id:
        if not _SESSION_ID_RE.match(raw_session_id):
            raise HTTPException(status_code=400, detail="invalid session_id format")
        session_id = raw_session_id
    else:
        session_id = str(uuid.uuid4())

    employee_id = claims["email"].split("@")[0]
    display_name = _DISPLAY_NAME_MAP.get(employee_id, _DEFAULT_DISPLAY_NAME)

    session_name = f"{CES_APP_NAME}/sessions/{session_id}"
    url = f"https://ces.googleapis.com/v1/{session_name}:runSession"
    input_text = f"（系統提示：這位員工的稱呼是「{display_name}」）\n{question}"
    payload = {
        "config": {
            "session": session_name,
            "deployment": CES_DEPLOYMENT_NAME,
        },
        "inputs": [{"text": input_text}],
    }

    token = _get_ces_token()
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.post(
            url,
            json=payload,
            headers={"Authorization": f"Bearer {token}"},
        )

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Agent error: {resp.text}")

    outputs = resp.json().get("outputs", [])
    answer = outputs[0].get("text", "") if outputs else ""

    return {
        "user": claims["email"],
        "question": question,
        "answer": answer,
    }


def _ces_location() -> str:
    """從 CES_APP_NAME 擷取 location，預設 us。"""
    m = re.search(r"/locations/([^/]+)/", CES_APP_NAME or "")
    return m.group(1) if m else "us"


@app.post("/stream")
async def stream(body: dict, claims: dict = Depends(verify_token)):
    """用 BidiRunSession WebSocket 向 CES 送出問題，以 SSE 串流回傳 AI 回答。"""
    if not CES_APP_NAME:
        raise HTTPException(status_code=503, detail="Agent not configured")

    question = body.get("question", "").strip()
    if not question:
        raise HTTPException(status_code=400, detail="question is required")

    raw_session_id = body.get("session_id", "").strip()
    if raw_session_id and _SESSION_ID_RE.match(raw_session_id):
        session_id = raw_session_id
    else:
        session_id = str(uuid.uuid4())

    employee_id = claims["email"].split("@")[0]
    display_name = _DISPLAY_NAME_MAP.get(employee_id, _DEFAULT_DISPLAY_NAME)
    session_name = f"{CES_APP_NAME}/sessions/{session_id}"
    input_text = f"（系統提示：這位員工的稱呼是「{display_name}」）\n{question}"

    location = _ces_location()
    ces_uri = (
        f"wss://ces.googleapis.com/ws/google.cloud.ces.v1"
        f".SessionService/BidiRunSession/locations/{location}"
    )
    gcp_token = _get_ces_token()

    async def event_stream():
        try:
            async with websockets.connect(
                ces_uri,
                additional_headers={"Authorization": f"Bearer {gcp_token}"},
            ) as ces_ws:
                await ces_ws.send(json.dumps({"config": {"session": session_name}}))
                await ces_ws.send(json.dumps({"realtimeInput": {"text": input_text}}))

                try:
                    async for raw in ces_ws:
                        data = json.loads(raw)
                        if "sessionOutput" in data:
                            text = data["sessionOutput"].get("text", "")
                            if text:
                                yield f"data: {json.dumps({'text': text})}\n\n"
                        elif "endSession" in data:
                            yield f"data: {json.dumps({'end': True})}\n\n"
                            break
                except websockets.exceptions.ConnectionClosed:
                    # CES 正常關閉 session，不視為錯誤
                    pass
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
