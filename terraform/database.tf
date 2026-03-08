# ==========================================
# 私有服務存取 (Private Service Access)
# ==========================================

# A. 在 VPC 中畫出一塊保留的內部 IP 區段給 Google 服務使用
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "google-managed-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16                                 # 這會保留一個 /16 的區段
  network       = google_compute_network.main_vpc.id # 本專案的 VPC
}

# B. 建立私有連線 (Peering)，將你的 VPC 與 Google 服務網路接通
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# ==========================================
# Cloud SQL PostgreSQL 實例
# ==========================================

resource "google_sql_database_instance" "postgres_instance" {
  name             = "bank-ai-db-instance"
  database_version = "POSTGRES_15" # 支援 pgvector 的版本
  region           = "asia-east1"

  # 確保在私有連線建立後才開始建立資料庫
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier            = "db-f1-micro" # 最小規格，省錢首選
    disk_size       = 10
    disk_type       = "PD_SSD"
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled    = false                              # 重要：關閉公網 IP
      private_network = google_compute_network.main_vpc.id # 指定走內網
    }

    # 銀行級別建議：開啟備份
    backup_configuration {
      enabled = true
    }
  }

  # 防止誤刪：實務上建議設為 true，但在 POC 練習時可設為 false 方便砍掉重練
  deletion_protection = false
}

# 建立資料庫本體
resource "google_sql_database" "chatbot_db" {
  name     = "chatbot_db"
  instance = google_sql_database_instance.postgres_instance.name
}

# 建立資料庫使用者
resource "google_sql_user" "db_user" {
  name     = "bff_user"
  instance = google_sql_database_instance.postgres_instance.name
  password = "your-password-here" # Day 15 我們會改用 Secret Manager
}

# ==========================================
# GCS Bucket (存放原始 Excel)
# ==========================================

resource "google_storage_bucket" "excel_storage" {
  name          = "bank-ai-excel-assets-${google_sql_database_instance.postgres_instance.project}" # 加上 project ID 確保名稱唯一
  location      = "ASIA-EAST1"
  force_destroy = true # 刪除 terraform 時一併刪除內容

  public_access_prevention    = "enforced" # 強制禁止公網存取
  uniform_bucket_level_access = true       # 統一權限管理
}