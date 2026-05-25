# 🔀 BFF — Backend For Frontend

> ⚠️ **架構更新 (Day 18+)**: 隨著專案導入 Google CX Agent Studio，BFF 的角色已發生轉變。原有的部分規劃已封存，請參考下方最新說明。

## 最新角色定位 (As of Day 18)

BFF 現在是 **CX Agent 的後端工具 (Tool) 提供者**，主要職責是：
1.  **身分驗證**: 維持不變，依然透過 Firebase ID Token 驗證使用者身分。
2.  **代理請求**: 將 Client 的請求代理給 CX Agent Studio 的 `runSession` API。
3.  **提供 RAG 工具**: 未來將提供一個 `/vector-search` 端點，讓 CX Agent 能透過 Tool Calling 的方式，回頭呼叫 BFF 來查詢 Cloud SQL 中的向量資料庫。

## 最新資料流

```
Client  ──(ID Token + Query)──►  BFF  ──(runSession API)──►  CX Agent
                                  ▲                           │
                                  │ (Tool Call)               │
                                  └────── /vector-search ─────┘
```

---

## 🗄️ 封存：原始規劃 (Day 1-17)

<details>
<summary>點此展開原始規劃</summary>

## 本地開發設定

```bash
# 1. 建立虛擬環境並安裝套件
cd bff
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 2. 啟動開發伺服器
FIREBASE_PROJECT_ID=your-firebase-project-id uvicorn main:app --port 8080 --reload
```

> 注意：本地執行前須先完成 `gcloud auth application-default login`，
> BFF 使用 ADC（Application Default Credentials）驗證 Firebase Token，不需要 SA key 檔。

## 功能說明

BFF 是 Client 和 Agent 之間的中介層，負責：
1. 驗證使用者身分（Firebase ID Token）
2. 轉發查詢請求到 Agent
3. 回傳 Agent 結果給 Client

## 資料流

```
Client  ──(ID Token + Query)──►  BFF  ──(Internal VPC)──►  Agent
Client  ◄──────(AI Response)──  BFF  ◄────────────────────  Agent
```

## 技術選型

- **Python FastAPI** + **Uvicorn**（D14 確定）

## GCP 對應服務

| 功能 | GCP 服務 |
|------|---------|
| 部署 | Cloud Run |
| 身分驗證 | IAM Auth（驗證 ID Token）|
| 內部通訊 | VPC Access Connector |
| 訪問 Cloud SQL | Private IP via VPC |
| Secret | Secret Manager |

## Service Account

- SA Name: `chatbot-bff-sa`
- 已建立並綁定 Cloud Run（Day 3-4）

## API 設計（規劃中）

```
POST /query
  Body: { "question": "OWASP SQL Injection 怎麼防範？" }
  Header: Authorization: Bearer <ID_TOKEN>
  Response: { "answer": "...", "sources": [...] }
```

## API

| Endpoint | Auth | 說明 |
|---|---|---|
| `GET /health` | 不需要 | 健康檢查 |
| `POST /query` | Firebase ID Token | 查詢（D14 回 placeholder） |

```
POST /query
  Header: Authorization: Bearer <FIREBASE_ID_TOKEN>
  Body:   { "question": "OWASP SQL Injection 怎麼防範？" }
  200:    { "user": "...", "question": "...", "answer": "..." }
  401:    Token 缺失 / 無效 / 過期
  403:    email 未驗證 或 非 ^\d{8}@cathaybk\.com\.tw$
```

## 狀態

- [x] Python FastAPI 框架（D14）
- [x] Firebase ID Token 驗證（D14）
- [x] 公司帳號限制 `^\d{8}@cathaybk\.com\.tw$`（D14）
- [x] Cloud Run 部署 Dockerfile（D14）
- [ ] `/query` 串接 Agent（D15+）
- [ ] Secret Manager 整合（D15）

</details>

---
*Last Updated: 2026-05-25*
