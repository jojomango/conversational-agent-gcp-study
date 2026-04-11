# 🏦 Bank AI Knowledge Base POC — Monorepo

> **學習目標**：透過實作銀行級知識庫系統，系統性學習 GCP 服務與企業安全架構。

## 📁 專案結構

```
chat-bot/
├── client/        # 前端：使用者自然語言介面
├── bff/           # Backend For Frontend：請求中介 & Auth
├── agent/         # Conversational Agent + 爬蟲 (OWASP)
├── terraform/     # Infrastructure state（可刪除的運算/網路/資料庫資源）
├── terraform-data/# Data state（長期保留的資料資源，如 GCS bucket）
├── SCOPE.md       # GCP 學習計劃 & 進度追蹤
└── CONTEXT.md     # AI 查詢用 Context 文件 (可直接貼給 Gemini)
```

## Terraform State 策略（重要）

本專案採用雙 state，避免 `make down` 被資料保留策略卡住：

- `terraform/`：infra state
  - 管理 Cloud Run、Cloud SQL、VPC、NAT、Firewall 等可重建資源
  - `make down` 只會 destroy 這一層

- `terraform-data/`：data state
  - 管理長期保留資料資源（目前為 GCS bucket）
  - 不受 `make down` 影響，作為向量資料重建來源（source of truth）

這樣可確保：
- 開發演練時可反覆清空 infra
- 原始資料不會被誤刪
- 成本與資料安全都可控

## 🏗 架構概覽

```
使用者
  │ 自然語言輸入
  ▼
[client]  ─── HTTP/WS ───►  [bff]  ─── Internal ───►  [agent]
                                                           │
                                              ┌────────────┘
                                              │  查詢知識庫
                                              ▼
                                        [Cloud SQL]  ◄──  爬蟲定期更新
                                      (OWASP 規範)        (Cloud Run Jobs)
```

## 🔧 GCP 服務使用

| 服務 | 用途 | 狀態 |
|------|------|------|
| Cloud Run | BFF Service 部署 | ✅ Done (D14) |
| Cloud SQL (PostgreSQL) | 知識庫儲存 | ✅ Done (D8) |
| Artifact Registry | Docker Image 管理 | ✅ Done (D13) |
| Cloud Run Jobs | Crawler / Vectorize Pipeline | ✅ Done (D10-D11) |
| Cloud Scheduler | 自動化觸發 | 📅 D11 |
| Firebase / IAM Auth | 身分驗證 | ✅ Done (D14) |
| Secret Manager | 憑證管理 | 📅 D15 |
| Vertex AI | RAG / Gemini API | 📅 D25-26 |
| VPC / Firewall / NAT | 網路安全 | ✅ Done (D6, D9) |
| Terraform | IaC | ✅ Done (D5) |

## 📍 當前狀態

- D14 已完成：BFF 已改為 FastAPI + Firebase ID Token 驗證，Client 有本地測試頁可登入並呼叫 `/query`
- 爬蟲與向量化流程已落地：`crawler/` 產 raw JSON，`ingestion/` 產 embedding 並寫入 Cloud SQL pgvector
- Agent 服務尚未接上：BFF `/query` 目前仍回 placeholder，D15 先處理 Secret Manager 與密碼管理

## 🌍 雙環境說明

| 環境 | GCP 權限 | Repo | 備註 |
|------|----------|------|------|
| 個人 side project | Owner | 本 repo | 完全控制 |
| 公司 Lab | 有限（無組織層級） | 獨立 repo | 另一台機器操作 |

## 🚀 基礎設施管理 (Makefile)

為了方便在開發期間節省成本，我們提供了快捷指令來管理 GCP 資源 (透過 Terraform)：

| 指令 | 用途 |
|------|------|
| `make up` | 先部署 `terraform-data`（資料層），再部署 `terraform`（基礎設施層） |
| `make db-off` | 僅銷毀 Cloud SQL 資料庫 (保留其他網路與運算資源)，節省 DB 閒置費用 |
| `make db-on` | 重新部署原本被銷毀的 Cloud SQL 資料庫 |
| `make down` | 僅銷毀 `terraform` 管理的 infra 資源（保留 `terraform-data`） |

## 📄 詳細進度
請見 [SCOPE.md](./SCOPE.md)

---
*Last Updated: 2026-04-11*
