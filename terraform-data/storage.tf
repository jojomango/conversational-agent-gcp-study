locals {
  chatbot_bff_sa_email = "chatbot-bff-sa@your-gcp-project-id.iam.gserviceaccount.com"
}

resource "google_storage_bucket" "excel_storage" {
  name          = "bank-ai-excel-assets-your-gcp-project-id"
  location      = "ASIA-EAST1"
  force_destroy = false

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "sa_storage_access" {
  bucket = google_storage_bucket.excel_storage.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.chatbot_bff_sa_email}"
}
