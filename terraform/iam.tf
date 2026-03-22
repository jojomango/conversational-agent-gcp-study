#custom role for cloud run operator
resource "google_project_iam_custom_role" "cloudrun_customrole" {
  description = "具有cloud run的觀看和重啟權限"
  permissions = ["run.revisions.list", "run.services.get", "run.services.list", "run.services.update"]
  project     = var.project_id
  role_id     = "Cloudrun.CustomRoleV2"
  title       = "BFF cloud run operator"
  stage       = "GA"
}

# service account for chatbot bff (managed outside Terraform)
# 直接使用 email，避免 data source 需要 iam.serviceAccounts.get 權限
locals {
  chatbot_bff_sa_email = "${var.service_account_name}@${var.project_id}.iam.gserviceaccount.com"
}

# 讓 Cloud Run Jobs 可透過 Cloud SQL connector 連線到資料庫
resource "google_project_iam_member" "sa_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${local.chatbot_bff_sa_email}"
}

# 讓 ingestion job 可呼叫 Vertex AI Embedding 模型
resource "google_project_iam_member" "sa_vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${local.chatbot_bff_sa_email}"
}

# 讓 Cloud Run Jobs 可從 Artifact Registry pull image
resource "google_project_iam_member" "sa_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.chatbot_bff_sa_email}"
}
