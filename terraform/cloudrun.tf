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
      # TODO: 先用 Google 的範例 Hello 鏡像，之後再換成bff的image
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {
        container_port = 8080
      }
    }
  }
}

# 2. 權限設定：只准你自己 (公司帳號) 訪問
resource "google_cloud_run_v2_service_iam_member" "allow_me" {
  location = google_cloud_run_v2_service.bff_service.location
  name     = google_cloud_run_v2_service.bff_service.name
  role     = "roles/run.invoker"
  # TODO: 暫時設定為自己可以觸發cloud run, 之後要改成公司成員都可以觸發
  member = "user:you@example.com"
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
        image = "gcr.io/${var.project_id}/bank-vectorize:latest"

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
