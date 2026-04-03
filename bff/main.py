import os
import re

import firebase_admin
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth

# ─── 環境變數 ────────────────────────────────────────────────────────────────

FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")
# 多個 origin 以逗號分隔，例如：http://localhost:5500,https://client-xxx-uc.a.run.app
ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS", "http://localhost:5500,http://localhost:8000"
).split(",")

# 公司帳號規則：八碼員編 + @cathaybk.com.tw
_COMPANY_EMAIL_RE = re.compile(r"^\d{8}@cathaybk\.com\.tw$")

# 開發用白名單：以逗號分隔的 email，例如 ALLOWED_EMAILS=you@gmail.com
# 生產環境（Cloud Run）保持空值，只走公司 domain 規則
_ALLOWED_EMAILS: set[str] = {
    e.strip().lower()
    for e in os.getenv("ALLOWED_EMAILS", "").split(",")
    if e.strip()
}


def _validate_env():
    if not FIREBASE_PROJECT_ID:
        raise RuntimeError("Missing required env var: FIREBASE_PROJECT_ID")


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


@app.post("/query")
async def query(body: dict, claims: dict = Depends(verify_token)):
    """
    接受使用者問題，回傳 AI 回答。
    D14: placeholder，Agent 串接留待 D15+ 實作。
    """
    return {
        "user": claims["email"],
        "question": body.get("question", ""),
        "answer": "（Agent 尚未串接，D15+ 實作）",
    }
