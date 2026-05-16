# 🏗 Terraform — Infra State

> 本資料夾是「infra state」，管理可重建的運算/網路/資料庫資源。
> 資料層（GCS bucket）已拆到 `terraform-data/`，避免 `make down` 因保留資料策略而中止。

## 檔案結構

```
terraform/
├── provider.tf      # GCP Provider 設定
├── network.tf       # VPC, Subnets, Firewall, VPC Connector
├── iam.tf           # Service Account, IAM Roles
├── cloudrun.tf      # Cloud Run 服務定義
├── database.tf       # Cloud SQL, Private Service Access
└── storage_ref.tf    # 讀取 terraform-data 管理的 bucket (data source)
```

## 與 terraform-data 的關係

- `terraform/`（本資料夾）:
    - 會被 `make down` destroy
    - 用於日常開發重建

- `terraform-data/`（另一個 state）:
    - 管理長期資料資源（目前為 GCS bucket）
    - 不會被 `make down` 刪除

Makefile 流程：
- `make up`：先 apply `terraform-data/`，再 apply `terraform/`
- `make down`：只 destroy `terraform/`

## 已完成資源

### 🌐 Network (`network.tf`)
- VPC: `bank-ai-vpc`（region: asia-east1）
- Private Subnet
- Firewall Rules
- VPC Access Connector（Cloud Run ↔ Private IP）

### 🔐 IAM (`iam.tf`)
- Service Account: `chatbot-bff-sa`
- 綁定必要 IAM 角色

### 🚀 Cloud Run (`cloudrun.tf`)
- Service: `chatbot-bff`
- 使用實際 BFF image（`asia-east1-docker.pkg.dev/<project>/bank-ai/bank-bff:latest`）
- VPC Connector 綁定（egress: ALL_TRAFFIC）
- 入口公開，由 BFF 應用層負責 Firebase JWT 驗證與公司帳號限制

### 🧪 Cloud Run Jobs (`crawler.tf` / `cloudrun.tf`)
- `bank-crawler-job`：抓 OWASP 原始資料並寫入 GCS
- `bank-vectorize-job`：讀取 GCS raw JSON，產 embedding 並寫入 Cloud SQL pgvector

### 🗄 Cloud SQL (`database.tf`)
- **[已註解]** PostgreSQL 15 + pgvector（保留作為未來自建 RAG 實驗參考）
- 原因：專案改用 CX Agent Studio 托管知識庫
- 要重新啟用：取消 database.tf 中的註解
- 省錢：註解後節省約 $10/月

### 🔐 Secret Manager (`secrets.tf`)
- **[保留參考]** 未來若需真正的密碼管理（如 API Keys）可參考
- D17+: CES 憑證改用 Terraform Variable，不使用 Secret Manager
- 原因：ces_app_name/ces_deployment_name 只是配置資訊，不是密碼
- 省錢：不使用 Secret Manager，節省 ~$0.24/月

## 使用方式

### 基本操作

```bash
cd terraform/

# 初始化
terraform init

# 預覽變更
terraform plan

# 套用
terraform apply

# 銷毀（僅 infra state）
terraform destroy
```

### CX Agent 憑證設定

D17+ 改用 **Terraform Variable** 傳遞 CX Agent 憑證（不使用 Secret Manager）：

**部署流程**：

```bash
# 1. 確保 env/dev.mk 或 env/lab.mk 中有設定 CES 變數
# env/lab.mk 範例：
CES_APP_NAME=projects/YOUR_PROJECT/locations/us/apps/YOUR_APP_ID
CES_DEPLOYMENT_NAME=projects/YOUR_PROJECT/locations/us/apps/YOUR_APP_ID/deployments/YOUR_DEPLOYMENT_ID

# 2. 使用 Makefile 自動傳遞變數
make up ENV=lab

# 或手動傳遞
cd terraform
terraform apply \
  -var=project_id=YOUR_PROJECT \
  -var=ces_app_name="projects/..." \
  -var=ces_deployment_name="projects/..."
```

**優點**：
- ✅ 簡化部署流程（不需手動建立 secret versions）
- ✅ 降低成本（不使用 Secret Manager）
- ✅ 配置集中在 env/*.mk（與其他環境變數一致）

**注意**：
- 這些值會進入 Terraform state file（已 gitignore）
- 本地開發仍用 `env/dev.mk`，不受影響

## 進度

| 資源 | 狀態 | 對應天 |
|------|------|--------|
| network.tf | ✅ Done | D6 |
| iam.tf | ✅ Done | D3-4 |
| cloudrun.tf |⏸️ 保留參考ice + Vectorize Job) | D14 |
| crawler.tf | ✅ Done | D10 |
| database.tf | ⏸️ Commented (保留參考) | D8 |
| secrets.tf | ✅ Done (僅 CES 憑證) | D17 |
| scheduler.tf | 📅 尚未加入 | D11+ |

## 注意事項

- `terraform.tfstate` 已加入 `.gitignore`（包含敏感資訊）
- 若發生資源搬移（例如 bucket 從 infra state 拆到 data state），需用 `terraform state rm/import` 對齊 state
- 個人環境：Owner 權限，可完整操作
- 公司 Lab：主要透過 `env/lab.mk` 覆蓋 project 相關變數，且組織層級資源無法修改

---
*Last Updated: 2026-05-16*
