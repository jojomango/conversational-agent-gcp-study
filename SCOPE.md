# Project: Bank AI Knowledge Base POC

## 📌 專案願景
建立一個銀行級安全的知識庫系統，允許員工以自然語言查詢 OWASP 等公開規範，並具備自動化爬蟲更新機制。

## 🏗 當前架構 (Updated: Day 14)
- **運算平台**: Cloud Run (BFF / Client / Crawler)
- **網路安全**: VPC, Private Subnets, VPC Access Connector (已完成)
- **身分驗證**: Google IAM-based Auth (取代 IAP 以節省成本)
- **資料庫**: Cloud SQL PostgreSQL & Cloud Storage (已完成部署)
- **基礎設施即代碼**: Terraform

## 📅 執行進度表 (W1-W5)

### Week 1: Identity & Foundation (Completed ✅)
- [x] D1-D2: Resource Hierarchy (Org/Folder/Project)
- [x] D3-D4: IAM & Custom Roles (SA: `chatbot-bff-sa`)
- [x] D5: Terraform Setup
- [x] D6: Networking (VPC: `bank-ai-vpc`, Subnets, Firewall)
- [x] D7: Cloud Run & VPC Connector & IAM Auth

### Week 2: Deployment & Integration (Next 🔜)
- [x] D8: Cloud SQL (Private IP) & GCS & VPC Connection Test
- [x] D9: Cloud NAT & Cloud Router: 讓私有 Cloud Run 能透過固定 IP 訪問外部網站
- [x] D10: Crawler 實作 (Cloud Run Job): 爬取 OWASP 官網內容並暫存至 GCS
- [x] D11: Data Ingestion Pipeline: 讀取爬蟲資料 -> 呼叫 Embedding API -> 存入 Cloud SQL
- [x] D12: Metadata 分類設計: 在入庫時自動標籤 (Category: A01-A10, Stack: Frontend/Backend)
- [x] D13: Artifact Registry 遷移: GCR → AR (asia-east1)，cleanup_policies keep 3，Makefile build-push targets
- [x] D14: Firebase Auth 與身分驗證整合 (確保 Client 端安全)

### Week 3: AI Logic & Conversational Agent (核心大腦) (In Progress 🚧)
- [x] D15: CX Agent Studio 多層級架構: Root Agent + Subagents (General/Security)，意圖路由與 API Access 部署模式
- [x] D16: BFF 整合 CX Agent API (runSession) + Client 聊天介面: Session ID 由 Client 維護實現多輪對話，Login 與 Chat 分頁
- [x] D17: Secret Manager: 安全儲存 CX Agent 憑證、資料庫密碼與 API Keys
- [x] D18: Agent Instruction 優化: General Agent 回轉 Root 路由 + Security Agent 強制優先使用 Data Store
- [-] D18 (原定計劃): Agent 進階功能: Session Parameters 與對話記憶 (Context Carry-over) ← 換用 Vertex AI Agent Engine 後，Session 記憶由平台原生處理，無需在 BFF 自行實作
- [x] D19: CES Agent 回歸測試
- [-] D19 (原定計劃): Tool/Function Calling: 設計 Agent 呼叫 BFF Vector Search 的 Webhook ← 換用 Vertex AI + GCS Data Store 後，RAG 查詢由平台原生處理，BFF Webhook 繞路架構不再需要
- [x] D20: CES Log 分析使用者歷程: 研究對話 log 分析方法，了解路由成功率與常見查詢模式
- [-] D20 (原定計劃): Vector Search 實作: 在 BFF 寫 SQL 指令進行「預過濾 (Metadata) + 向量比對」← 換用 Vertex AI 後向量搜尋由平台處理，Cloud SQL pgvector 自建 SQL 查詢整層不再需要
- [x] D21: 串流對話體驗 (BidiRunSession): 改用 WebSocket 實作逐字輸出，Client 顯示打字效果

### Week 4: RAG Deep Dive & Security (深度研發) (Future 📅)
- [-] D22: Query Expansion: 使用 Gemini 處理「那前端呢？」這種帶有 Context 的追問
- [x] D22: Agent安全性
- [ ] D23 — BFF Rate Limiting + Audit Log
- [-] D23: Prompt Engineering: 設計 Gemini 的總結邏輯，確保只根據 SQL 資料回答
- [ ] D24: VPC Service Controls: 建立服務邊界，防止向量數據外洩
- [ ] D25: Private Service Connect (PSC): 嘗試以更私密的方式存取 Vertex AI

### Week 5: Monitoring, CI/CD & Final Review (Future 📅)
- [ ] D26: Logging & Monitoring: 追蹤對話成功率、Token 消耗量與 SQL 查詢速度
- [ ] D27: Budget Alerts (預算警告) 與 Cloud Run 效能調優 (冷啟動優化)
- [ ] D28: CI/CD Pipeline (Cloud Build): 實現程式碼更動後自動部署至 Cloud Run
- [ ] D29-D30: 最終架構評審: 撰寫專案報告，比較「自建 RAG (方案 B)」與「Data Store (方案 A)」的成本與效能差異。

## 🛠 技術債與待辦事項
- [ ] 測試 Cloud Run 是否能成功透過 VPC Connector 存取 Private IP 資源。
- [ ] D17+: CX Agent 憑證改用 Terraform Variable，部署時自動從 env/*.mk 傳入（不需手動建立 secret versions）。

---
*Last Updated: 2026-05-16*