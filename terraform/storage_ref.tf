# Bucket is managed in separate Terraform state (terraform-data/).
# Infra state reads it as an existing resource to avoid destroy conflicts.
locals {
  assets_bucket_name = var.assets_bucket_name
}

data "google_storage_bucket" "excel_storage" {
  name = local.assets_bucket_name
}
