# 🏦 Bank AI Knowledge Base POC — Monorepo

> **學習目標**：透過實作銀行級知識庫系統，系統性學習 GCP 服務與企業安全架構。

## 📁 專案結構

```
chat-bot/
├── client/        # 前端：聊天介面（Login + Chat，WebSocket 串流）
├── bff/           # Backend For Frontend：Auth、Rate Limiting、CX Agent 串接、audit log
├── crawler/       # OWASP 爬蟲，輸出 raw JSON 到 GCS
├── ingestion/     # raw JSON chunk + embedding 後寫入 Cloud SQL pgvector（批次入庫）
├── agent/         # Agent 技術選型文件（已決定採用 CX Agent Studio）
├── ces-agnets/    # CX Agent Studio 匯出的 Agent 設定備份
├── terraform/     # Infrastructure state（Cloud Run / SQL / VPC / VPC-SC / PSC / Monitoring）
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
[client]  ── WebSocket (BidiRunSession) ──►  [bff]  ── runSession / BidiRunSession ──►  [CX Agent]
                                                                                      (Vertex AI Agent Engine)
                                                                                              │
                                                                            Root Agent 路由 → General / Security Subagent
                                                                                              │
                                                                                  原生 Data Store 查詢 (GCS)
                                                                                              ▲
                                                                                爬蟲定期更新 (Cloud Run Jobs)
```

Cloud SQL (pgvector) 現僅用於 `ingestion/` 批次入庫留存，request-time 的 RAG 查詢已由 CX Agent 原生 Data Store 取代。

## 🔧 GCP 服務使用

| 服務 | 用途 | 狀態 |
|------|------|------|
| Cloud Run | BFF Service 部署 | ✅ Done (D14) |
| Cloud SQL (PostgreSQL) | 向量資料批次入庫 | ✅ Done (D8) |
| Artifact Registry | Docker Image 管理 | ✅ Done (D13) |
| Cloud Run Jobs | Crawler / Vectorize Pipeline | ✅ Done (D10-D11) |
| Firebase / IAM Auth | 身分驗證 | ✅ Done (D14) |
| Secret Manager | 憑證管理 | ✅ Done (D17) |
| Vertex AI Agent Engine (CX Agent Studio) | 對話式 Agent、意圖路由、RAG | ✅ Done (D15-D21) |
| VPC / Firewall / NAT | 網路安全 | ✅ Done (D6, D9) |
| VPC Service Controls | 服務邊界，防止向量資料外洩 | ✅ Done (D24) |
| Private Service Connect | 私密存取 Vertex AI | ✅ Done (D25) |
| Cloud Monitoring / Logging | Audit log、log-based metric、Dashboard | ✅ Done (D26) |
| Budget Alerts | 預算警告 | ✅ Done (D27) |
| Cloud Build / Cloud Deploy | CI/CD Pipeline | 🚧 D28 進行中 |
| Terraform | IaC | ✅ Done (D5) |

## 📍 當前狀態

- D27 已完成：Week 5（Monitoring, CI/CD & Final Review）進行中，目前進度到 D28
- 對話邏輯已改用 **CX Agent Studio (Vertex AI Agent Engine)**：Root Agent + General/Security Subagent 意圖路由，RAG 查詢與 Session 記憶皆由平台原生處理
- `client` 已是正式聊天介面（Login + Chat），透過 WebSocket 以逐字流式輸出呈現回覆
- `bff` 已完成 Firebase 驗證、公司帳號限制、Rate Limiting、CX Agent 串接與 audit log（成功/失敗、latency_ms）
- 進行中 **D28**：CI/CD Pipeline — git flow（main / staging / release）與 Cloud Build + Cloud Deploy 架構已寫成 IaC，尚未連接真實 GitHub repo 與 prod project，相關資源目前皆條件式跳過（見 [terraform/cicd.tf](terraform/cicd.tf)、[terraform/clouddeploy.tf](terraform/clouddeploy.tf)）

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

## 🛠️ 技術債與待辦事項
- **VPC Connector 連通性**: 測試 Cloud Run 是否能成功透過 VPC Connector 存取 Private IP 資源。
- **CX Agent 憑證管理** (D17+): 改用 Terraform Variable，部署時自動從 `env/*.mk` 傳入，不需手動建立 secret versions。

> 註：原「BFF `/vector-search` Webhook 供 CX Agent 呼叫」的技術債已隨 D19-D20 架構調整（改用 Vertex AI + GCS Data Store 原生 RAG）一併移除，不再適用。

---
*Last Updated: 2026-07-16*
