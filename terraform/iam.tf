#custom role for cloud run operator
resource "google_project_iam_custom_role" "cloudrun_customrole" {
  description = "具有cloud run的觀看和重啟權限"
  permissions = ["run.revisions.list", "run.services.get", "run.services.list", "run.services.update"]
  project     = "your-gcp-project-id"
  role_id     = "Cloudrun.CustomRoleV2"
  title       = "BFF cloud run operator"
  stage       = "GA"
}

# service account for chatbot bff
resource "google_service_account" "chatbot_bff_sa" {
  account_id   = "chatbot-bff-sa"
  description  = "用於 BFF 呼叫 Dialogflow 與讀寫 Cloud Storage"
  display_name = "chatbot-bff-sa"
  project      = "your-gcp-project-id"
}