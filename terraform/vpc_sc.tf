# D24: VPC Service Controls
# 在 GCP API 層建立服務邊界，防止即使拿到 SA key 的攻擊者從邊界外竊取資料
#
# 前置條件：需要組織層級帳號才能建立 Access Policy
# org_id 空白時，以下三個資源全部跳過，make up 不受影響

# 1. Access Policy（組織層級容器，整個 org 只需要一個）
resource "google_access_context_manager_access_policy" "main" {
  count  = var.org_id != "" ? 1 : 0
  parent = "organizations/${var.org_id}"
  title  = "bank-ai-policy"
}

# 2. Access Level（從邊界外進來的通行證條件）
# combining_function = OR：符合任一條件即可通過
resource "google_access_context_manager_access_level" "trusted_access" {
  count  = var.org_id != "" ? 1 : 0
  parent = google_access_context_manager_access_policy.main[0].name
  name   = "${google_access_context_manager_access_policy.main[0].name}/accessLevels/trusted_access"
  title  = "trusted_access"

  basic {
    combining_function = "OR"

    # 條件一：開發者 IP（讓你能從筆電執行 terraform apply / gcloud 指令）
    conditions {
      ip_subnetworks = var.developer_ip_ranges
    }

    # 條件二：BFF Service Account（允許跨 project 呼叫時不受邊界限制）
    conditions {
      members = [
        "serviceAccount:${local.chatbot_bff_sa_email}",
      ]
    }
  }
}

# 3. Service Perimeter（邊界本體）
# use_explicit_dry_run_spec = true：目前為 dry-run，只記錄 log 不真正阻擋
# 確認 log 無誤後，移除此旗標即可切換成 enforced 模式
resource "google_access_context_manager_service_perimeter" "bank_ai_perimeter" {
  count  = var.org_id != "" ? 1 : 0
  parent = google_access_context_manager_access_policy.main[0].name
  name   = "${google_access_context_manager_access_policy.main[0].name}/servicePerimeters/bank_ai_perimeter"
  title  = "bank_ai_perimeter"

  use_explicit_dry_run_spec = true

  spec {
    # 哪個 GCP Project 在邊界內（需要 project number，不接受 project id 字串）
    resources = ["projects/${var.project_number}"]

    # 受保護的 GCP API（邊界外的請求若未符合 Access Level 條件則被拒絕）
    restricted_services = [
      "storage.googleapis.com",       # GCS：crawler 原始資料 & 向量前處理資料
      "aiplatform.googleapis.com",    # Vertex AI：AI Agent & Embedding API
      "sqladmin.googleapis.com",      # Cloud SQL Admin：pgvector 向量資料庫
      "secretmanager.googleapis.com", # Secret Manager：憑證 & API keys
    ]

    # 引用上方定義的通行證
    access_levels = [
      google_access_context_manager_access_level.trusted_access[0].name,
    ]
  }
}
