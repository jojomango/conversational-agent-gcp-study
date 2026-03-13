# Lab 遷移待辦清單

> 進入公司 Lab 環境前/後的行動清單。  
> 此文件為「參考提醒」，不是 runbook；實際指令請依當時架構狀態調整。

---

## 一、進入 Lab 前：必問 Admin 的問題

### Reset 範圍
- [ ] 3 個月 reset 是刪整個 GCP Project，還是只清空帳單/quota？
- [ ] Reset 後 GCS bucket 與其中的物件是否保留？
- [ ] Service Account 和 Custom IAM Role 是否被刪除？
- [ ] Artifact Registry / GCR image 是否被清空？
- [ ] Cloud SQL instance 和資料是否被刪除？

### 帳號權限
- [ ] 我在 Lab Project 的 IAM 角色是？（期望：roles/owner 或同等）
- [ ] 能否建立 Service Account？（需要 `roles/iam.serviceAccountAdmin`）
- [ ] 能否建立 Custom IAM Role？（需要 `roles/iam.roleAdmin`）
- [ ] 能否使用 Private Service Access（`servicenetworking.googleapis.com`）？
- [ ] Vertex AI Embedding API 在 Lab 是否已啟用或可請求啟用？

### 費用限制
- [ ] Lab 的 spending cap 是多少？
  - 參考：Cloud SQL db-f1-micro ≈ $10/月；Vertex AI embedding 依呼叫量計費
- [ ] 超額後是「暫停資源」還是「刪除資源」？
- [ ] 是否可以對特定資源（如 Cloud SQL）申請費用例外？

---

## 二、進入 Lab 後：初始設定

- [ ] 更新 `env/lab.mk`，填入正確的 Lab `PROJECT_ID`
- [ ] 確認 `gcloud config set project <LAB_PROJECT_ID>` 已切換
- [ ] 確認以下 APIs 已啟用（或手動啟用）：
  - `run.googleapis.com`
  - `sqladmin.googleapis.com`
  - `servicenetworking.googleapis.com`
  - `storage.googleapis.com`
  - `aiplatform.googleapis.com`
  - `vpcaccess.googleapis.com`
  - `cloudbuild.googleapis.com`
  - `iam.googleapis.com`

---

## 三、資源策略（可拋棄 vs 需保留）

| 資源 | 策略 | 說明 |
|------|------|------|
| Cloud SQL | 可拋棄 | 向量資料可從 raw JSON 重新 reindex |
| GCS raw JSON | **需保留** | 備份到本地 `crawler/data/raw/`，已在 repo 中 |
| GCR/Artifact Registry image | 可拋棄 | 可從本地 source 重新 build |
| Terraform state（local） | **需保留** | 在本機 repo，不放 GCS，重建安全 |
| IAM SA / Custom Role | 可拋棄 | Terraform 管理，重建快 |
| VPC / 網路設定 | 可拋棄 | Terraform 管理 |

---

## 四、Reset 後重建順序（預計 30–60 分鐘）

1. 啟用必要 GCP APIs
2. `make up ENV=lab` — 重建 data state (GCS) + infra state (SQL、VPC、Jobs)
3. 重新 build & push images（若 GCR 被清空）：
   ```
   gcloud builds submit crawler --tag gcr.io/<PROJECT_ID>/bank-crawler:latest
   gcloud builds submit ingestion --tag gcr.io/<PROJECT_ID>/bank-vectorize:latest
   ```
4. `make pipeline-local ENV=lab` — 上傳本地 raw JSON → reindex 向量

> **瓶頸**：Cloud SQL 建立約需 10–15 分鐘，其餘步驟都很快。

---

## 五、需要調整的項目（進 Lab 後再處理）

- [ ] `env/lab.mk` 填入正確 Lab PROJECT_ID
- [ ] `terraform/variables.tf` default 值是否要改（或靠 lab.mk 傳入就好）
- [ ] `cloudrun.tf` 的 `allow_me` member email 改為 Lab 帳號
- [ ] `database.tf` 的 DB password 改用 Secret Manager（Day 15 計畫中）
- [ ] Makefile 是否需要新增 `enable-apis` / `build-push` 等 Lab 專用目標
  - **等架構穩定後再加，避免現在做了又要改**

---

*Last Updated: 2026-03-13*
