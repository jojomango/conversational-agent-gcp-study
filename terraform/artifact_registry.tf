resource "google_artifact_registry_repository" "bank_ai" {
  location      = var.region
  repository_id = "bank-ai"
  format        = "DOCKER"

  # AR 掃描預設關閉，避免額外費用
  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-3-most-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = 3
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"

    condition {
      tag_state = "ANY"
    }
  }
}
