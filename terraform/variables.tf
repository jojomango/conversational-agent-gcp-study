variable "project_id" {
  description = "GCP project ID for infra state"
  type        = string
  default     = "your-gcp-project-id"
}

variable "region" {
  description = "GCP region for infra resources"
  type        = string
  default     = "asia-east1"
}

variable "service_account_name" {
  description = "Service account short name (without domain)"
  type        = string
  default     = "chatbot-bff-sa"
}

variable "assets_bucket_name" {
  description = "Name of data-state managed GCS bucket"
  type        = string
  default     = "bank-ai-excel-assets-your-gcp-project-id"
}

variable "firebase_project_id" {
  description = "Firebase Project ID（與 GCP Project ID 不同，啟用 Firebase 時會加後綴，例如 your-gcp-project-id-a9e0f）"
  type        = string
  default     = "your-firebase-project-id"
}

variable "ces_app_name" {
  description = "CX Agent Studio App Name（完整路徑：projects/.../locations/us/apps/...）"
  type        = string
  default     = ""
}

variable "ces_deployment_name" {
  description = "CX Agent Studio Deployment Name（完整路徑：projects/.../deployments/...）"
  type        = string
  default     = ""
}

# D24: VPC Service Controls
variable "org_id" {
  description = "GCP Organization ID（執行 gcloud organizations list 取得）"
  type        = string
  default     = ""
}

variable "developer_ip_ranges" {
  description = "開發者 IP 清單，允許從邊界外呼叫受保護的 GCP API（格式：CIDR，例如 1.2.3.4/32）"
  type        = list(string)
  default     = []
}

variable "project_number" {
  description = "GCP Project Number（執行 gcloud projects list 取得，Service Perimeter resources 欄位需要數字 ID）"
  type        = string
  default     = ""
}

# D28: CI/CD — prod project（示意用，目前尚未真的建立）
variable "prod_project_id" {
  description = "prod 環境的 GCP Project ID。留空時，release trigger 與 Cloud Deploy pipeline/prod target 全部跳過（見 cicd.tf），只作為架構示意，不會對不存在的 project 執行 apply"
  type        = string
  default     = ""
}

variable "prod_region" {
  description = "prod 環境的 region，留空時沿用 var.region"
  type        = string
  default     = ""
}

# D27: Budget Alerts
variable "billing_account_id" {
  description = "GCP Billing Account ID（執行 gcloud beta billing accounts list 取得，格式 XXXXXX-XXXXXX-XXXXXX）。空白時 budget.tf 資源全部跳過（例如公司 Lab 通常沒有帳務權限）"
  type        = string
  default     = ""
}

variable "budget_amount_twd" {
  description = "每月預算金額（新台幣），達到門檻比例時觸發通知"
  type        = number
  default     = 1000
}

variable "budget_alert_email" {
  description = "Budget 告警通知信箱。空白時仍會用 GCP 預設對象（Billing Account Administrator/User）收到通知，只是不會額外建立 notification channel"
  type        = string
  default     = ""
}
