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
# 使用 data source：SA 已手動建立於 GCP，Terraform 只讀取不管理生命週期
# make down 時不會刪除，避免 30 天 soft-delete 保護期造成重建失敗
data "google_service_account" "chatbot_bff_sa" {
  account_id = "chatbot-bff-sa"
  project    = "your-gcp-project-id"
}
