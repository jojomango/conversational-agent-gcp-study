# 1. 定義 VPC
resource "google_compute_network" "main_vpc" {
  name                    = "bank-ai-vpc"
  auto_create_subnetworks = false # 銀行規範：嚴禁自動創建
}

# 2. 定義子網 (開啟 Private Google Access)
resource "google_compute_subnetwork" "bff_subnet" {
  name                     = "bff-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "asia-east1" # 建議設在台灣
  network                  = google_compute_network.main_vpc.id
  private_ip_google_access = true # 這就是關鍵！
}

# 3. 預留給 Serverless Connector 的網段
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "vpc-connector-subnet"
  ip_cidr_range = "10.8.0.0/28"
  region        = "asia-east1"
  network       = google_compute_network.main_vpc.id
}
