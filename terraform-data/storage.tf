locals {
  chatbot_bff_sa_email = "${var.service_account_name}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_storage_bucket" "excel_storage" {
  name          = var.assets_bucket_name
  location      = var.assets_bucket_location
  force_destroy = false

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "sa_storage_access" {
  bucket = google_storage_bucket.excel_storage.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.chatbot_bff_sa_email}"
}
