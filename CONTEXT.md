# 📋 CONTEXT.md — AI 查詢用 Context 文件

> **用途**：直接貼給 Gemini / ChatGPT 等 AI 工具使用，提供完整專案背景。
> **維護**：每次有進度更新時同步更新此文件。
> **Last Updated**: 2026-04-11

---

## 1. 專案簡介

**專案名稱**：Bank AI Knowledge Base POC  
**目的**：學習 GCP，同時建立一個可讓使用者以自然語言查詢 OWASP 等安全規範的知識庫系統。

## 2. Monorepo 結構

```
chat-bot/
├── client/         # D14 本地測試頁：Firebase Login + 呼叫 BFF /query
├── bff/            # FastAPI BFF：驗 Firebase ID Token、限制公司帳號
├── crawler/        # OWASP 爬蟲，輸出 raw JSON 到本地 / GCS
├── ingestion/      # 將 raw JSON chunk + embedding 後寫入 Cloud SQL pgvector
├── agent/          # Agent API 規劃與技術選型文件（尚未實作服務）
├── terraform/      # Infra state：Cloud Run / SQL / VPC / Jobs
└── terraform-data/ # Data state：長期保留 GCS bucket
```

## 3. 資料流

```
使用者 → [client] → [bff] → [agent] → [Cloud SQL (OWASP 規範)]
                                ↑
                          爬蟲定期更新 (Cloud Run Jobs + Cloud Scheduler)
```

目前狀態補充：
- `client` 已有 D14 測試頁，可登入 Google、取得 Firebase ID Token、直接呼叫 BFF `/query`
- `bff` 已完成 Firebase 驗證與公司帳號限制，但 `/query` 仍回 placeholder
- `agent` 服務尚未實作，查詢邏輯尚未從 BFF 拆出

## 4. 當前 GCP 架構

- **運算**: Cloud Run BFF Service + Cloud Run Jobs (Crawler / Vectorize)
- **網路**: VPC `bank-ai-vpc`、Private Subnets、VPC Access Connector
- **IAM / Auth**: Service Account `chatbot-bff-sa` + Firebase ID Token 驗證
- **資料庫**: Cloud SQL PostgreSQL（Private IP，已部署）
- **儲存**: GCS bucket（由 `terraform-data/` 管理 raw JSON）
- **IaC**: Terraform 雙 state（infra / data 分離）

## 5. 學習進度

### ✅ 完成 (Week 1–2)
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

### 🔜 目前位置 (Week 3)
- **D15**: Secret Manager：移除 Terraform / Cloud Run Job 中的明碼 DB password

### 📅 計劃中 (Week 3–5)
- D16: BFF `/query` 串接 Agent / retrieval
- D17: Private Service Connect (Vertex AI)
- D18-D19: Retrieval / security hardening
- D22-24: Logging, Monitoring, Budget Alerts
- D25-26: Vertex AI & RAG (Gemini API)
- D27: CI/CD (Cloud Build)
- D28-30: Final Architecture Review

## 6. 技術債 / 待辦

- [ ] 測試 Cloud Run → VPC Connector → Private IP 資源連通性
- [ ] 將 D14 測試頁升級為正式前端 UI
- [ ] 實作 Agent 服務或 retrieval 邏輯，取代 BFF placeholder response

## 7. 雙環境策略

| | 個人環境 | 公司 Lab |
|---|---|---|
| GCP 角色 | Owner | 有限（無組織層級權限） |
| Repo | 本 repo (chat-bot) | 獨立 repo（另一台機器）|
| Terraform | 完整控制 | 僅限 Lab 資源|

## 8. Agent 技術選型（待決定）

**選項 A**: Vertex AI Agent Builder（GCP 原生，托管服務）  
**選項 B**: 自建 Gemini API + LangChain（更彈性，自行管理）

> 詳見 `agent/README.md`

## 9. 目前可運作的最小流程

1. 執行 `crawler/` 取得 OWASP raw JSON
2. 透過 `ingestion/` 將資料寫入 Cloud SQL + pgvector
3. 用 `client/` 測試頁登入 Firebase，拿 ID Token 呼叫 `bff/` 的 `/query`
4. `bff/` 驗證 token 與 email 規則後，回傳 placeholder response

## 10. AI 協作提示

- 若要修改目前實作狀態，請以 `bff/main.py`、`client/index.html`、`crawler/main.py`、`ingestion/main.py`、`terraform/*.tf` 為準
- `README.md` 是專案總覽，`SCOPE.md` 是進度主檔，本文件是給 AI 的精簡快照

---
*此文件由 SCOPE.md 彙整，可直接貼給 AI 作為 context。*
