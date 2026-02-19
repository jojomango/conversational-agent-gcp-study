# 🔀 BFF — Backend For Frontend

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

## 技術選型（待定）

暫定選項：
- **Python FastAPI**：輕量、與 GCP SDK 生態整合好
- **Node.js Express**：前端開發者熟悉

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

## 狀態

- [ ] 框架選型確認
- [ ] Firebase ID Token 驗證實作（Day 12-13）
- [ ] `/query` endpoint 實作
- [ ] Cloud Run 部署（Dockerfile）
- [ ] Secret Manager 整合（Day 15）

---
*Last Updated: 2026-02-19*
