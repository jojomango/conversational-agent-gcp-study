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
