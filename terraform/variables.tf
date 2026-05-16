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
  description = "Firebase Project ID（與 GCP Project ID 不同，啟用 Firebase 時會加後綴，例如 your-firebase-project-id）"
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
