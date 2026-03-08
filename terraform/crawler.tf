# (Bucket 已經在 database.tf 中的 excel_storage 定義了，不需要重複建立)
# 2. 定義 Cloud Run Job
resource "google_cloud_run_v2_job" "crawler_job" {
  name     = "bank-crawler-job"
  location = "asia-east1"

  # 連結我們建立的 Service Account (具有存取 GCS 的權限)
  template {
    service_account = google_service_account.chatbot_bff_sa.email

    # 重要：加入 VPC Connector，否則爬蟲不會透過 NAT 使用固定 IP 出外網
    vpc_access {
      connector = google_vpc_access_connector.main_connector.id
      egress    = "ALL_TRAFFIC" # 強制對外網路也走 VPC 隧道
    }

    template {
      containers {
        image = "gcr.io/${var.project_id}/bank-crawler:v1" # 使用我們剛打包的 Image

        env {
          name  = "GCS_BUCKET_NAME"
          value = google_storage_bucket.excel_storage.name # 使用 database.tf 中的 bucket
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

  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image]
  }
}