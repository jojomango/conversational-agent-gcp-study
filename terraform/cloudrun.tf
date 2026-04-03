# 1. 定義 Cloud Run 服務 (BFF)
resource "google_cloud_run_v2_service" "bff_service" {
  name     = "chatbot-bff"
  location = var.region

  # 銀行級安全：只允許透過認證的請求 (取代 IAP 的方案)
  ingress = "INGRESS_TRAFFIC_ALL"

  # 允許 terraform destroy 刪除此服務 (POC 練習用)
  deletion_protection = false

  template {
    # 連結我們 Day 5 做的 Service Account
    service_account = local.chatbot_bff_sa_email

    vpc_access {
      # 連結你剛剛做好的隧道
      connector = google_vpc_access_connector.main_connector.id
      # 強制所有流量 (包含連外網) 都走 VPC 隧道
      egress = "ALL_TRAFFIC"
    }

    containers {
      image = "asia-east1-docker.pkg.dev/${var.project_id}/bank-ai/bank-bff:latest"

      ports {
        container_port = 8080
      }

      env {
        name  = "FIREBASE_PROJECT_ID"
        value = var.firebase_project_id
      }

      # D15 改用 Secret Manager 注入；暫時允許本地 client 測試頁
      env {
        name  = "ALLOWED_ORIGINS"
        value = "http://localhost:5500,http://localhost:8000"
      }
    }
  }
}

# 2. 權限設定：公開入口，由 BFF 應用層做 Firebase JWT 驗證與公司帳號限制
# （取代原本只允許個人 Google 帳號的 IAM invoker 模式）
resource "google_cloud_run_v2_service_iam_member" "allow_public" {
  location = google_cloud_run_v2_service.bff_service.location
  name     = google_cloud_run_v2_service.bff_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# 3. 定義 Cloud Run Job (Ingestion / Vectorize)
resource "google_cloud_run_v2_job" "vectorize_job" {
  name     = "bank-vectorize-job"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account = local.chatbot_bff_sa_email

      vpc_access {
        connector = google_vpc_access_connector.main_connector.id
        egress    = "ALL_TRAFFIC"
      }

      containers {
        image = "asia-east1-docker.pkg.dev/${var.project_id}/bank-ai/bank-vectorize:latest"

        env {
          name  = "GCS_BUCKET_NAME"
          value = data.google_storage_bucket.excel_storage.name
        }

        env {
          name  = "GCS_PREFIX"
          value = "raw/"
        }

        env {
          name  = "DB_NAME"
          value = google_sql_database.chatbot_db.name
        }

        env {
          name  = "DB_USER"
          value = google_sql_user.db_user.name
        }

        # TODO: Day 15 改用 Secret Manager 注入
        env {
          name  = "DB_PASSWORD"
          value = "your-password-here"
        }

        # 使用 Cloud SQL Private IP 直連
        env {
          name  = "DB_HOST"
          value = google_sql_database_instance.postgres_instance.private_ip_address
        }

        env {
          name  = "DB_PORT"
          value = "5432"
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "VERTEX_REGION"
          value = var.region
        }

        env {
          name  = "EMBEDDING_MODEL"
          value = "text-embedding-005"
        }

        env {
          name  = "MAX_BLOBS"
          value = "20"
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      timeout = "900s"
    }
  }

  depends_on = [
    google_project_iam_member.sa_cloudsql_client,
    google_project_iam_member.sa_vertex_ai_user,
  ]
}
