# 🤖 Agent — Conversational Agent

> ⚠️ **架構更新 (Day 18+)**: 本專案已決定採用 **Google CX Agent Studio** 作為對話式 AI 的核心，取代原先自建 RAG 的方案。原技術選型比較已封存於下方。

## CX Agent Studio 核心概念

本專案將圍繞 CX Agent Studio 的三大核心功能進行開發：

### 1. Tools (Function Calling)
- **目的**: 讓 Agent 能夠呼叫外部 API 來獲取它自身不知道的資訊。
- **本專案應用**:
    - 將在 CX Agent Studio 中定義一個名為 `VectorSearch` 的 Tool。
    - 這個 Tool 會指向我們 BFF 服務上的一個新端點 (例如 `/vector-search`)。
    - 當 Agent 需要查詢 OWASP 知識庫時，它會呼叫這個 Tool，並將使用者的問題傳遞給 BFF。
    - BFF 執行向量搜尋後，將結構化結果回傳給 Agent。

### 2. Prompt Engineering
- **目的**: 指導 Agent 如何思考、回應以及使用工具。這是控制 Agent 行為的核心。
- **本專案應用**:
    - **總結能力**: 我們會設計 Prompt，指示 Agent 在收到 `VectorSearch` Tool 的回傳結果後，必須用自然、專業的語言進行總結，並嚴格基於回傳的資料作答。
    - **上下文理解**: 我們會引導 Agent 利用其內建的對話歷史來理解追問 (例如 "那前端呢？")，並在必要時調整後續 Tool 的呼叫參數。

### 3. Session Management
- **目的**: 在多輪對話中維持上下文和狀態。
- **本專案應用**:
    - **對話歷史**: 主要依賴 CX Agent 內建的對話記憶能力，透過 `session_id` 來串連每一輪的問答。
    - **Session Parameters**: 實驗性地使用 Session Parameters 來儲存對話中的關鍵資訊 (例如，用戶當前關注的 OWASP 分類)，以便在後續的對話或 Tool 呼叫中加以利用。

---

## 🗄️ 封存：原始技術選型 (Day 1-17)

<details>
<summary>點此展開原始規劃</summary>

## 功能說明

本目錄目前主要存放 Conversational Agent 的規劃與技術選型。

實際已落地的資料管線分散在：
1. `crawler/`：抓取 OWASP 原始內容並輸出 raw JSON
2. `ingestion/`：對 raw JSON 做 chunk、embedding、寫入 Cloud SQL pgvector
3. `bff/`：接收查詢，但目前 `/query` 還是 placeholder response

也就是說，**Crawler 已實作，但 Agent API 服務尚未實作**。

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

</details>

---
*Last Updated: 2026-05-25*
- [ ] Retrieval / prompt / memory 設計
- [ ] Agent API 實作與部署

---
*Last Updated: 2026-04-11*
