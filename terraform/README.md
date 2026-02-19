# 🏗 Terraform — Infrastructure as Code

> GCP 資源皆透過 Terraform 管理，確保基礎設施可重現、可版控。

## 檔案結構

```
terraform/
├── provider.tf      # GCP Provider 設定
├── network.tf       # VPC, Subnets, Firewall, VPC Connector
├── iam.tf           # Service Account, IAM Roles
├── cloudrun.tf      # Cloud Run 服務定義
└── (規劃中)
    ├── cloudsql.tf  # Cloud SQL (Day 8)
    ├── scheduler.tf # Cloud Scheduler (Day 11)
    └── secrets.tf   # Secret Manager (Day 15)
```

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
- 使用 placeholder image（`us-docker.pkg.dev/cloudrun/container/hello`）
- VPC Connector 綁定（egress: ALL_TRAFFIC）
- IAM：僅允許指定 user 呼叫

> **TODO**: 將 placeholder image 換成實際 BFF 的 Docker image（Day 9 後）

## 使用方式

```bash
cd terraform/

# 初始化
terraform init

# 預覽變更
terraform plan

# 套用
terraform apply
```

## 進度

| 資源 | 狀態 | 對應天 |
|------|------|--------|
| network.tf | ✅ Done | D6 |
| iam.tf | ✅ Done | D3-4 |
| cloudrun.tf | ✅ Done (placeholder) | D7 |
| cloudsql.tf | 📅 規劃中 | D8 |
| scheduler.tf | 📅 規劃中 | D11 |
| secrets.tf | 📅 規劃中 | D15 |

## 注意事項

- `terraform.tfstate` 已加入 `.gitignore`（包含敏感資訊）
- 個人環境：Owner 權限，可完整操作
- 公司 Lab：需調整 `provider.tf` 中的 project ID，且組織層級資源無法修改

---
*Last Updated: 2026-02-19*
