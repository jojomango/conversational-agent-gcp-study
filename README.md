# 🏦 Bank AI Knowledge Base POC — Monorepo

> **學習目標**：透過實作銀行級知識庫系統，系統性學習 GCP 服務與企業安全架構。

## 📁 專案結構

```
chat-bot/
├── client/        # 前端：使用者自然語言介面
├── bff/           # Backend For Frontend：請求中介 & Auth
├── agent/         # Conversational Agent + 爬蟲 (OWASP)
├── terraform/     # Infrastructure as Code (GCP 資源定義)
├── SCOPE.md       # GCP 學習計劃 & 進度追蹤
└── CONTEXT.md     # AI 查詢用 Context 文件 (可直接貼給 Gemini)
```

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
| Cloud Run | client / bff / agent 部署 | ✅ Done (D7) |
| Cloud SQL (PostgreSQL) | 知識庫儲存 | 📅 D8 |
| Artifact Registry | Docker Image 管理 | 📅 D9 |
| Cloud Run Jobs | 定期爬蟲 | 📅 D10 |
| Cloud Scheduler | 自動化觸發 | 📅 D11 |
| Firebase / IAM Auth | 身分驗證 | 📅 D12-13 |
| Secret Manager | 憑證管理 | 📅 D15 |
| Vertex AI | RAG / Gemini API | 📅 D25-26 |
| VPC / Firewall / NAT | 網路安全 | ✅ Done (D6) |
| Terraform | IaC | ✅ Done (D5) |

## 🌍 雙環境說明

| 環境 | GCP 權限 | Repo | 備註 |
|------|----------|------|------|
| 個人 side project | Owner | 本 repo | 完全控制 |
| 公司 Lab | 有限（無組織層級） | 獨立 repo | 另一台機器操作 |

## 📄 詳細進度
請見 [SCOPE.md](./SCOPE.md)

---
*Last Updated: 2026-02-19*
