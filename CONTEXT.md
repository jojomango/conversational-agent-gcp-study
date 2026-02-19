# 📋 CONTEXT.md — AI 查詢用 Context 文件

> **用途**：直接貼給 Gemini / ChatGPT 等 AI 工具使用，提供完整專案背景。
> **維護**：每次有進度更新時同步更新此文件。
> **Last Updated**: 2026-02-19

---

## 1. 專案簡介

**專案名稱**：Bank AI Knowledge Base POC  
**目的**：學習 GCP，同時建立一個可讓使用者以自然語言查詢 OWASP 等安全規範的知識庫系統。

## 2. Monorepo 結構

```
chat-bot/
├── client/     # 前端 (尚未實作)
├── bff/        # Backend For Frontend (尚未實作)
├── agent/      # Conversational Agent + 爬蟲 (尚未實作)
└── terraform/  # IaC，目前已完成 Week 1
```

## 3. 資料流

```
使用者 → [client] → [bff] → [agent] → [Cloud SQL (OWASP 規範)]
                                ↑
                          爬蟲定期更新 (Cloud Run Jobs + Cloud Scheduler)
```

## 4. 當前 GCP 架構

- **運算**: Cloud Run (BFF / Client / Crawler 服務)
- **網路**: VPC `bank-ai-vpc`、Private Subnets、VPC Access Connector
- **IAM**: Google IAM-based Auth、Service Account `chatbot-bff-sa`
- **資料庫**: Cloud SQL PostgreSQL（Private IP，**尚未實作**）
- **IaC**: Terraform（已完成網路、IAM、Cloud Run 基本設定）

## 5. 學習進度

### ✅ 完成 (Week 1, Day 1–7)
- D1-D2: Resource Hierarchy (Org/Folder/Project)
- D3-D4: IAM & Custom Roles
- D5: Terraform Setup
- D6: Networking (VPC, Subnets, Firewall)
- D7: Cloud Run & VPC Connector & IAM Auth

### 🔜 進行中 (Week 2, Day 8–14)
- **D8**: Cloud SQL (Private IP) & VPC Connection Test ← **目前位置**
- D9: Artifact Registry & Docker Packaging
- D10: Cloud Run Jobs (Crawler)
- D11: Cloud Scheduler
- D12-13: Firebase Auth & Identity-Based Auth
- D14: Cloud Run Optimization

### 📅 計劃中 (Week 3–5)
- D15: Secret Manager
- D16: Cloud NAT (固定爬蟲出口 IP)
- D17: Private Service Connect (Vertex AI)
- D19: VPC Service Controls
- D22-24: Logging, Monitoring, Budget Alerts
- D25-26: Vertex AI & RAG (Gemini API)
- D27: CI/CD (Cloud Build)
- D28-30: Final Architecture Review

## 6. 技術債 / 待辦

- [ ] 測試 Cloud Run → VPC Connector → Private IP 資源連通性
- [ ] 實作前端 Firebase Login，換取 ID Token 打 BFF
- [ ] 設定 Cloud NAT 固定爬蟲出口 IP

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

## 9. 尚未實作的元件

- `client/`：前端 UI（框架待定）
- `bff/`：Python FastAPI 或 Node.js（待定）
- `agent/`：技術選型待確認後實作

---
*此文件由 SCOPE.md 彙整，可直接貼給 AI 作為 context。*
