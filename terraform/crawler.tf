# (Bucket 已經在 database.tf 中的 excel_storage 定義了，不需要重複建立)
# 2. 定義 Cloud Run Job
resource "google_cloud_run_v2_job" "crawler_job" {
  name     = "bank-crawler-job"
  location = var.region

  # 允許 Terraform 刪除此 Job，避免 make down 報錯
  deletion_protection = false

  template {
    template {
      # 連結我們建立的 Service Account (具有存取 GCS 的權限)
      service_account = local.chatbot_bff_sa_email

      # 重要：加入 VPC Connector，否則爬蟲不會透過 NAT 使用固定 IP 出外網
      vpc_access {
        connector = google_vpc_access_connector.main_connector.id
        egress    = "ALL_TRAFFIC" # 強制對外網路也走 VPC 隧道
      }

      containers {
        image = "asia-east1-docker.pkg.dev/${var.project_id}/bank-ai/bank-crawler:latest"

        env {
          name  = "GCS_BUCKET_NAME"
          value = data.google_storage_bucket.excel_storage.name # 使用 terraform-data state 管理的 bucket
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }

      # 設定執行超時 (爬蟲通常很快，5分鐘綽綽有餘)
      timeout = "300s"
    }
  }
}
