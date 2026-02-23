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
- [ ] D9: Artifact Registry & Docker Packaging
- [ ] D10: Cloud Run Jobs (Crawler Implementation)
- [ ] D11: Cloud Scheduler (Automation)
- [ ] D12-D13: Firebase Auth & Identity-Based Auth Integration
- [ ] D14: Cloud Run Optimization (Cold Start / Concurrency)

### Week 3: Enterprise Security (Planned)
- [ ] D15: Secret Manager (DB Credentials / AI Keys)
- [ ] D16: Cloud NAT (Static Outbound IP for Crawler)
- [ ] D17: Private Service Connect (Vertex AI Private Access)
- [ ] D19: VPC Service Controls (Data Exfiltration Protection)

### Week 4-5: AI & Monitoring & Finalization
- [ ] D22-D24: Logging, Monitoring, Budget Alerts
- [ ] D25-D26: Vertex AI & RAG (Gemini API)
- [ ] D27: CI/CD (Cloud Build)
- [ ] D28-D30: Final Architecture Review & Proposal

## 🛠 技術債與待辦事項
- [ ] 測試 Cloud Run 是否能成功透過 VPC Connector 存取 Private IP 資源。
- [ ] 實作前端 Firebase Login 以換取進入 BFF 的 ID Token。
- [ ] 設定 Cloud NAT 以固定爬蟲出口 IP。

---
*Last Updated: 2026-02-23*