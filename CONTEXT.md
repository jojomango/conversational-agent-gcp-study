# 📋 CONTEXT.md — AI 查詢用 Context 文件

> **用途**：直接貼給 Gemini / ChatGPT 等 AI 工具使用，提供完整專案背景。
> **維護**：每次有進度更新時同步更新此文件。
> **Last Updated**: 2026-07-08

---

## 1. 專案簡介

**專案名稱**：Bank AI Knowledge Base POC  
**目的**：學習 GCP，同時建立一個可讓使用者以自然語言查詢 OWASP 等安全規範的知識庫系統。

## 2. Monorepo 結構

```
chat-bot/
├── client/         # 聊天介面：Firebase Login + WebSocket 串流呼叫 BFF
├── bff/            # FastAPI BFF：驗 Firebase ID Token、限制公司帳號、Rate Limiting、串接 CX Agent、audit log
├── crawler/        # OWASP 爬蟲，輸出 raw JSON 到本地 / GCS
├── ingestion/      # 將 raw JSON chunk + embedding 後寫入 Cloud SQL pgvector（批次入庫，非 request-time）
├── agent/          # Agent 技術選型文件（已決定採用 CX Agent Studio，實際 Agent 設定於 GCP CX Agent Studio 平台）
├── ces-agnets/     # CX Agent Studio 匯出的 Agent 設定備份
├── terraform/      # Infra state：Cloud Run / SQL / VPC / Jobs / VPC-SC / PSC / Monitoring
└── terraform-data/ # Data state：長期保留 GCS bucket
```

## 3. 資料流

```
使用者 → [client] ─WebSocket(BidiRunSession)─ [bff] ─runSession/BidiRunSession─ [CX Agent (Vertex AI Agent Engine)]
                                                                                        │
                                                                      Root Agent 路由 → General / Security Subagent
                                                                                        │
                                                                          原生 Data Store 查詢 (GCS, OWASP 內容)
                                                                                        ↑
                                                                    爬蟲定期更新 (Cloud Run Jobs → GCS)
```

目前狀態補充：
- `client` 已改為正式聊天介面（Login + Chat 分頁），Session ID 由 Client 維護以支援多輪對話，並以逐字流式輸出呈現回覆
- `bff` 已完成 Firebase 驗證、公司帳號限制、CX Agent API 串接（含 WebSocket 版 BidiRunSession）、Rate Limiting 與 audit log（query/stream 成功/失敗、latency_ms、reason）
- 對話邏輯已改用 **Google CX Agent Studio (Vertex AI Agent Engine)**：Root Agent + General/Security Subagent 做意圖路由，RAG 查詢與 Session 記憶皆由平台原生處理
- 原規劃「BFF 自建 Vector Search / Webhook 呼叫」已捨棄（見第 5 節 D19、D20 的變更說明），Cloud SQL pgvector 現僅用於資料入庫 (ingestion) 批次流程，不再有 request-time SQL 查詢

## 4. 當前 GCP 架構

- **運算**: Cloud Run BFF Service + Cloud Run Jobs (Crawler / Vectorize) + Vertex AI Agent Engine (CX Agent)
- **網路**: VPC `bank-ai-vpc`、Private Subnets、VPC Access Connector、Cloud NAT/Router、Private Service Connect（存取 Vertex AI）
- **IAM / Auth**: Service Account `chatbot-bff-sa` + Firebase ID Token 驗證
- **資料庫**: Cloud SQL PostgreSQL（Private IP，僅供 ingestion 批次入庫使用）
- **儲存**: GCS bucket（由 `terraform-data/` 管理 raw JSON，同時作為 CX Agent Data Store 來源）
- **憑證管理**: Secret Manager（CX Agent 憑證、DB 密碼、API Keys）
- **安全邊界**: VPC Service Controls（防止向量資料外洩）
- **監控**: BFF audit log（query/stream 成功/失敗、latency_ms）+ Terraform log-based metric + Cloud Monitoring Dashboard + CES 平台原生 metric (`app/token_consumption_count`、`app/session_count`)
- **IaC**: Terraform 雙 state（infra / data 分離）

## 5. 學習進度

### ✅ 完成 (Week 1–2: Identity & Foundation / Deployment & Integration)
- D1-D2: Resource Hierarchy (Org/Folder/Project)
- D3-D4: IAM & Custom Roles
- D5: Terraform Setup
- D6: Networking (VPC, Subnets, Firewall)
- D7: Cloud Run & VPC Connector & IAM Auth
- D8: Cloud SQL (Private IP) & VPC Connection Test
- D9: Cloud NAT & Cloud Router (固定爬蟲出口 IP)
- D10: Cloud Run Jobs (Crawler)
- D11: Data Ingestion Pipeline (GCS → Embedding → Cloud SQL pgvector)
- D12: Metadata 分類 (category, stack rule-based)
- D13: Artifact Registry 遷移 (GCR → AR, cleanup_policies, Makefile build-push)
- D14: Firebase Auth & Identity-Based Auth（BFF 驗證 + client 測試頁）

### ✅ 完成 (Week 3: AI Logic & Conversational Agent)
- D15: CX Agent Studio 多層級架構（Root Agent + General/Security Subagent，意圖路由）
- D16: BFF 整合 CX Agent API (runSession) + Client 聊天介面（Session ID 由 Client 維護，多輪對話）
- D17: Secret Manager（CX Agent 憑證、DB 密碼、API Keys）
- D18: Agent Instruction 優化（General Agent 回轉 Root 路由、Security Agent 強制優先用 Data Store）
  - ~~原定：Session Parameters 與對話記憶~~ → 改用 Vertex AI Agent Engine 後，Session 記憶由平台原生處理，BFF 不需自行實作
- D19: CES Agent 回歸測試
  - ~~原定：設計 BFF Vector Search Webhook 給 Agent 呼叫~~ → 改用 Vertex AI + GCS Data Store 後，RAG 查詢由平台原生處理，Webhook 繞路架構不再需要
- D20: CES Log 分析使用者歷程（路由成功率、常見查詢模式）
  - ~~原定：BFF 自建 SQL「預過濾 + 向量比對」~~ → 向量搜尋改由 Vertex AI 平台處理，Cloud SQL pgvector 自建查詢層不再需要
- D21: 串流對話體驗（BidiRunSession，改用 WebSocket 逐字輸出）

### ✅ 完成 (Week 4: RAG Deep Dive & Security)
- D22: Agent 安全性
  - ~~原定：Query Expansion（Gemini 處理帶 Context 的追問）~~
- D23: BFF Rate Limiting + Audit Log
  - ~~原定：Prompt Engineering（Gemini 總結邏輯，只根據 SQL 資料回答）~~
- D24: VPC Service Controls（建立服務邊界，防止向量資料外洩）
- D25: Private Service Connect (PSC)（更私密的方式存取 Vertex AI）

### ✅ 完成 (Week 5: Monitoring, CI/CD & Final Review — 進行中)
- D26: Logging & Monitoring：BFF 補 query/stream 完成時的成功/失敗 audit log（latency_ms、reason），Terraform 建 log-based metric（成功/失敗次數、latency 分布）+ Cloud Monitoring Dashboard，疊上 CES 平台原生 metric（`app/token_consumption_count`、`app/session_count`）
  - ~~原定：SQL 查詢速度~~ → 架構轉向 Vertex AI Data Store 後，Cloud SQL 只剩 ingestion 批次入庫用途，BFF 沒有 request-time SQL 可測，移除此項

### 🔜 目前位置 / 計劃中 (Week 5)
- **D27**: Budget Alerts（預算警告）與 Cloud Run 效能調優（冷啟動優化）
- D28: CI/CD Pipeline (Cloud Build)：程式碼更動後自動部署至 Cloud Run
- D29-D30: 最終架構評審：撰寫專案報告，比較「自建 RAG (方案 B)」與「Data Store (方案 A)」的成本與效能差異

## 6. 技術債 / 待辦

- [ ] 測試 Cloud Run → VPC Connector → Private IP 資源連通性
- [ ] D17+: CX Agent 憑證改用 Terraform Variable，部署時自動從 `env/*.mk` 傳入（不需手動建立 secret versions）

## 7. 雙環境策略

| | 個人環境 | 公司 Lab |
|---|---|---|
| GCP 角色 | Owner | 有限（無組織層級權限） |
| Repo | 本 repo (chat-bot) | 獨立 repo（另一台機器）|
| Terraform | 完整控制 | 僅限 Lab 資源|

## 8. Agent 技術選型（已決定，Day 18+）

**已採用**: Google **CX Agent Studio (Vertex AI Agent Engine)** — GCP 原生托管服務，Root Agent + General/Security Subagent 做意圖路由，RAG 查詢與 Session 記憶由平台原生處理。
**已捨棄**: 自建 Gemini API + LangChain + BFF 自建 Vector Search（原「方案 B」），僅保留作為 D29-D30 最終評審的成本/效能比較基準。

> 詳見 `agent/README.md`

## 9. 目前可運作的最小流程

1. 執行 `crawler/` 取得 OWASP raw JSON，寫入 GCS（同時作為 CX Agent Data Store 來源）
2. 透過 `ingestion/` 將資料寫入 Cloud SQL + pgvector（目前僅供批次入庫留存，非 request-time 查詢）
3. 使用者於 `client/` 聊天介面用 Google 登入，取得 Firebase ID Token
4. `client` 建立 Session，透過 WebSocket 呼叫 `bff/` 的串流端點
5. `bff/` 驗證 token 與公司帳號規則、套用 Rate Limiting，再以 BidiRunSession 呼叫 CX Agent
6. CX Agent（Root → General/Security Subagent）查詢 Data Store 並逐字串流回覆，`bff/` 同步寫入 audit log（成功/失敗、latency_ms）

## 10. AI 協作提示

- 若要修改目前實作狀態，請以 `bff/main.py`、`client/index.html`、`crawler/main.py`、`ingestion/main.py`、`terraform/*.tf` 為準
- `README.md` 是專案總覽，`SCOPE.md` 是進度主檔，本文件是給 AI 的精簡快照

---
*此文件由 SCOPE.md 彙整，可直接貼給 AI 作為 context。*
