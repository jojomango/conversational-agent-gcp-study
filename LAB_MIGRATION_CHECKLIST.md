# Lab 遷移待辦清單

> 進入公司 Lab 環境前/後的行動清單。  
> 此文件為「參考提醒」，不是 runbook；實際指令請依當時架構狀態調整。

---

## 一、進入 Lab 前：必問 Admin 的問題

### API / 服務權限
- [ ] **Cloud Run** 是否可用？（原申請為 GKE，需確認 `run.googleapis.com` 是否已開放）
  - 若不可用，備選方案為改回 GKE，但 `terraform/cloudrun.tf` 需大幅重寫
- [ ] Vertex AI Embedding API 在 Lab 是否已啟用或可請求啟用？
- [ ] 能否使用 Private Service Access（`servicenetworking.googleapis.com`）？

### 帳號權限
- [ ] 我在 Lab Project 的 IAM 角色是？（期望：`roles/owner` 或同等）
- [ ] 能否建立 Service Account？（需要 `roles/iam.serviceAccountAdmin`）
- [ ] 能否建立 Custom IAM Role？（需要 `roles/iam.roleAdmin`）

### Reset 範圍
- [ ] 3 個月 reset 是刪整個 GCP Project，還是只清空帳單/quota？
- [ ] Reset 後 GCS bucket 與其中的物件是否保留？
- [ ] Service Account 和 Custom IAM Role 是否被刪除？
- [ ] Artifact Registry image 是否被清空？
- [ ] Cloud SQL instance 和資料是否被刪除？

### 費用限制
- [ ] Lab 的 spending cap 是多少？
  - 參考：Cloud SQL db-f1-micro ≈ $10/月；Vertex AI embedding 依呼叫量計費
- [ ] 超額後是「暫停資源」還是「刪除資源」？

---

## 二、Clone 到 Lab 環境後：初始設定

```bash
# 1. 切換 gcloud 帳號（Lab 帳號與個人帳號不同）
gcloud auth login
gcloud config set project <LAB_PROJECT_ID>

# 或用 configuration 管理兩個帳號（不互相干擾）
gcloud config configurations create lab
gcloud config set account <lab-email>
gcloud config set project <LAB_PROJECT_ID>

# 2. 確認可用 API 清單
gcloud services list --enabled --project=<LAB_PROJECT_ID>
```

- [ ] 更新 `env/lab.mk`，填入正確的 Lab `PROJECT_ID`（`FIREBASE_PROJECT_ID` 保持不變，見第四節）
- [ ] 確認以下 APIs 已啟用（或手動啟用）：
  - `run.googleapis.com` ← **最優先確認，見第一節**
  - `sqladmin.googleapis.com`
  - `servicenetworking.googleapis.com`
  - `storage.googleapis.com`
  - `aiplatform.googleapis.com`
  - `vpcaccess.googleapis.com`
  - `artifactregistry.googleapis.com`
  - `iam.googleapis.com`
- [ ] 手動在 Lab Project 建立 Service Account `chatbot-bff-sa`（Terraform 不管理 SA 建立）
- [ ] 建立 `client/config.js`（已 gitignore，參考 `client/config.example.js`，內容不需改）

---

## 三、Terraform 需修改的項目

| 檔案 | 修改內容 | 說明 |
|------|---------|------|
| `env/lab.mk` | `PROJECT_ID` 改為 Lab Project ID | **唯一必改項目** |
| `env/lab.mk` | `FIREBASE_PROJECT_ID` 保持 `your-firebase-project-id` | Firebase 並用個人專案，不需改 |
| `terraform/variables.tf` | `default` 不需改 | 靠 `lab.mk` 傳入覆蓋即可 |
| `terraform/cloudrun.tf` | `FIREBASE_PROJECT_ID` 已改為 `var.firebase_project_id` | D14 已完成，不需再動 |
| `terraform/cloudrun.tf` | IAM `allow_public`（allUsers） | D14 已改為公開入口，不需再動 |
| `terraform/database.tf` | DB password | D15 改用 Secret Manager；進 Lab 前先沿用 env var |

> `make up ENV=lab` 會自動從 `env/lab.mk` 讀取所有值並傳給 Terraform，不需手動傳參。

---

## 四、Firebase Auth 策略（並用個人 Firebase 專案）

**結論：不需要在 Lab 開新 Firebase 專案。**

```
個人 Firebase 專案（your-firebase-project-id）
         ↓ 發出 ID Token
Lab BFF 用相同的 FIREBASE_PROJECT_ID 驗證 Token
         ↓
公司帳號規則 ^\d{8}@cathaybk\.com\.tw$ 照樣生效
```

- Firebase Auth Token 驗證只依賴 `FIREBASE_PROJECT_ID`，與 GCP Project 無關
- `env/lab.mk` 裡的 `FIREBASE_PROJECT_ID=your-firebase-project-id` 保持不變即可
- `client/config.js` 裡的 `firebaseConfig` 也不需要改

---

## 五、資源策略（可拋棄 vs 需保留）

| 資源 | 策略 | 說明 |
|------|------|------|
| Cloud SQL | 可拋棄 | 向量資料可從 raw JSON 重新 reindex |
| GCS raw JSON | **需保留** | 備份在 `crawler/data/raw/`，已在 repo 中 |
| Artifact Registry image | 可拋棄 | 可從本地 source 重新 build |
| Terraform state（local） | **需保留** | 在本機 repo，不放 GCS |
| IAM SA / Custom Role | 可拋棄 | Terraform 管理，重建快 |
| VPC / 網路設定 | 可拋棄 | Terraform 管理 |
| `client/config.js` | **需保留** | 已 gitignore，新機器需重新建立（參考 `config.example.js`） |

---

## 六、Reset 後重建順序（預計 30–60 分鐘）

1. 啟用必要 GCP APIs
2. 手動建立 SA `chatbot-bff-sa`（若被刪除）
3. `make up ENV=lab` — 重建 data state (GCS) + infra state (VPC、SQL、Cloud Run、Jobs)
4. 重新 build & push images（若 AR 被清空）：
   ```bash
   make build-push-crawler ENV=lab
   make build-push-vectorize ENV=lab
   make build-push-bff ENV=lab
   ```
5. `make pipeline-local ENV=lab` — 上傳本地 raw JSON → reindex 向量

> **瓶頸**：Cloud SQL 建立約需 10–15 分鐘，其餘步驟都很快。

---

*Last Updated: 2026-04-04 (D14 完成後更新)*
