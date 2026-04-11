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
- PostgreSQL 15（Private IP）
- 啟用 Private Service Access
- `chatbot_db` / `bff_user` 已建立
- DB password 目前仍是暫時值，D15 將改為 Secret Manager

## 使用方式

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

## 進度

| 資源 | 狀態 | 對應天 |
|------|------|--------|
| network.tf | ✅ Done | D6 |
| iam.tf | ✅ Done | D3-4 |
| cloudrun.tf | ✅ Done (BFF Service + Vectorize Job) | D14 |
| crawler.tf | ✅ Done | D10 |
| database.tf | ✅ Done | D8 |
| scheduler.tf | 📅 尚未加入 | D11+ |
| secrets.tf | 📅 規劃中 | D15 |

## 注意事項

- `terraform.tfstate` 已加入 `.gitignore`（包含敏感資訊）
- 若發生資源搬移（例如 bucket 從 infra state 拆到 data state），需用 `terraform state rm/import` 對齊 state
- 個人環境：Owner 權限，可完整操作
- 公司 Lab：主要透過 `env/lab.mk` 覆蓋 project 相關變數，且組織層級資源無法修改

---
*Last Updated: 2026-04-11*
