# 🤖 Agent — Conversational Agent & Crawler

## 功能說明

本元件負責兩件事：
1. **Conversational Agent**：接收來自 BFF 的自然語言查詢，搜尋知識庫並回答
2. **Crawler (爬蟲)**：定期或手動觸發，爬取 OWASP 等安全規範並存入 Cloud SQL

## 技術選型比較

### 選項 A：Vertex AI Agent Builder（托管服務）

**GCP 原生 RAG 平台，低程式碼整合**

```
優點：
✅ 與 GCP 深度整合（Cloud Storage, BigQuery, Vertex Search）
✅ 内建 Datastore（可直接吃爬蟲資料）
✅ 托管 RAG Pipeline，不用自己管 embedding / index
✅ 有 UI Console 可以測試 Agent
✅ 學習 GCP 服務本身的好機會

缺點：
❌ 較不彈性，難以自訂 retrieval 邏輯
❌ 費用可能比自建高
❌ Vendor lock-in 較重
❌ 部分功能在 Lab 環境可能受限
```

**適合場景**：想快速建立 proof-of-concept、重點在學 GCP 原生服務

---

### 選項 B：自建 Gemini API + LangChain（開源框架）

**自己管 RAG Pipeline，部署在 Cloud Run**

```
優點：
✅ 完全控制 retrieval、prompt、memory 邏輯
✅ 可以接任何資料庫（Cloud SQL PostgreSQL + pgvector）
✅ 跨雲可移植，不綁定 GCP
✅ 社群資源豐富

缺點：
❌ 需要自己管 embedding model、vector index
❌ 需要更多程式碼維護
❌ 需要自行處理 scaling
```

**適合場景**：想深入理解 RAG 原理、需要高度自訂

---

### 建議

> 🎯 **建議先用選項 B（Gemini API + LangChain + pgvector）**

理由：
- `client/bff/agent` 三層架構已確立，自建 Agent 更符合架構設計
- Cloud SQL with pgvector extension 是你 D8 的目標，可以直接延伸
- 學完之後，再嘗試用 Vertex AI Agent Builder 重構，形成對比學習
- 公司 Lab 環境可能沒有 Vertex AI Agent Builder 的完整權限

---

## 目錄結構（規劃中）

```
agent/
├── crawler/        # OWASP 爬蟲邏輯（Cloud Run Jobs）
│   ├── main.py
│   └── Dockerfile
├── api/            # Agent API（Cloud Run Service）
│   ├── main.py     # FastAPI endpoint
│   ├── rag.py      # RAG pipeline (LangChain + Gemini)
│   └── Dockerfile
└── README.md
```

## GCP 對應服務

| 功能 | GCP 服務 |
|------|---------|
| Agent API 部署 | Cloud Run (Service) |
| 爬蟲執行 | Cloud Run (Jobs) |
| 排程觸發 | Cloud Scheduler |
| 向量/知識庫 | Cloud SQL + pgvector |
| AI 推論 | Gemini API (Vertex AI) |
| Secret 管理 | Secret Manager |

## 狀態

- [ ] 技術選型確認（見上方比較）
- [ ] 環境變數設計
- [ ] Crawler 實作（Day 10）
- [ ] Agent API 實作（Day 25-26）

---
*Last Updated: 2026-02-19*
