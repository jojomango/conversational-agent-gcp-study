# Project: Bank AI Knowledge Base POC

## 📌 專案願景
建立一個銀行級安全的知識庫系統，允許員工以自然語言查詢 OWASP 等公開規範，並具備自動化爬蟲更新機制。

## 🏗 當前架構 (Updated: Day 11)
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

[ ] D12: Metadata 分類設計: 在入庫時自動標籤 (Category: A01-A10, Stack: Frontend/Backend)

[ ] D13: Artifact Registry 與 Docker 鏡像自動化管理 (CI 基礎)

[ ] D14: Firebase Auth 與身分驗證整合 (確保 Client 端安全)

### Week 3: AI Logic & Conversational Agent (核心大腦) (Future 📅)
- [ ] D15: Dialogflow CX (CA) 基礎: 建立 Agent、Start Page 與 OWASP 核心意圖
- [ ] D16: Session Parameters: 設計 CA 的記憶功能 (例如：記得用戶正在問 XSS)
- [ ] D17: OpenAPI Spec (Tool Call): 撰寫 Swagger 文件，定義 CA 如何呼叫 BFF
- [ ] D18: BFF Webhook 實作: 開發 Cloud Run API 接收來自 CA 的請求
- [ ] D19: Secret Manager: 安全儲存資料庫密碼與 API Keys，拒絕 Code 內寫死

### Week 4: RAG Deep Dive & Security (深度研發) (Future 📅)
- [ ] D20: Vector Search 實作: 在 BFF 寫 SQL 指令進行「預過濾 (Metadata) + 向量比對」
- [ ] D21: Query Expansion: 使用 Gemini 處理「那前端呢？」這種帶有 Context 的追問
- [ ] D22: Prompt Engineering: 設計 Gemini 的總結邏輯，確保只根據 SQL 資料回答
- [ ] D23: VPC Service Controls: 建立服務邊界，防止向量數據外洩
- [ ] D24: Private Service Connect (PSC): 嘗試以更私密的方式存取 Vertex AI

### Week 5: Monitoring, CI/CD & Final Review (Future 📅)
- [ ] D25: Logging & Monitoring: 追蹤對話成功率、Token 消耗量與 SQL 查詢速度
- [ ] D26: Budget Alerts (預算警告) 與 Cloud Run 效能調優 (冷啟動優化)
- [ ] D27: CI/CD Pipeline (Cloud Build): 實現程式碼更動後自動部署至 Cloud Run
- [ ] D28-D30: 最終架構評審: 撰寫專案報告，比較「自建 RAG (方案 B)」與「Data Store (方案 A)」的成本與效能差異。

## 🛠 技術債與待辦事項
- [ ] 測試 Cloud Run 是否能成功透過 VPC Connector 存取 Private IP 資源。
- [ ] 實作前端 Firebase Login 以換取進入 BFF 的 ID Token。

---
*Last Updated: 2026-03-05*