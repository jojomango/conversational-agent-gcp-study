# 1. 定義 VPC
resource "google_compute_network" "main_vpc" {
  name                    = "bank-ai-vpc"
  auto_create_subnetworks = false # 銀行規範：嚴禁自動創建
}

# 2. 定義子網 (開啟 Private Google Access)
resource "google_compute_subnetwork" "bff_subnet" {
  name                     = "bff-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = var.region # 建議設在台灣
  network                  = google_compute_network.main_vpc.id
  private_ip_google_access = true # 這就是關鍵！
}

# 3. 預留給 Serverless Connector 的網段
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "vpc-connector-subnet"
  ip_cidr_range = "10.8.0.0/28"
  region        = var.region
  network       = google_compute_network.main_vpc.id
}

# 定義防火牆
# 允許 VPC 內部互相溝通 (Internal Connectivity)
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-traffic"
  network = google_compute_network.main_vpc.name

  # 允許你定義的所有 10.x.x.x 網段互相通訊
  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp" # 方便你測試 ping
  }

  description = "允許 VPC 內部的子網互相溝通"
}

# 允許 Google 健康檢查 (Health Checks)
resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks"
  network = google_compute_network.main_vpc.name

  # 這些是 Google 特定的 Health Check IP 網段，固定不變
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
}

# IAP 遠端存取 (可選，建議)
resource "google_compute_firewall" "allow_iap_proxy" {
  name    = "allow-iap-proxy"
  network = google_compute_network.main_vpc.name

  source_ranges = ["35.235.240.0/20"] # IAP 專用網段

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

# VPC connector
resource "google_vpc_access_connector" "main_connector" {
  name   = "vpc-connector"
  region = var.region
  # 使用我們 Day 6 準備好的 10.8.0.0/28 子網
  subnet {
    name = google_compute_subnetwork.connector_subnet.name
  }
  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3
}

# 1. 申請一個靜態外部 IP (給 NAT 用)
resource "google_compute_address" "nat_ip" {
  name   = "bank-ai-nat-ip"
  region = var.region
}

# 2. 建立 Cloud Router
resource "google_compute_router" "router" {
  name    = "bank-ai-router"
  region  = var.region
  network = google_compute_network.main_vpc.id
}

# 3. 建立 Cloud NAT
resource "google_compute_router_nat" "nat_config" {
  name                   = "bank-ai-nat"
  router                 = google_compute_router.router.name
  region                 = var.region
  nat_ip_allocate_option = "MANUAL_ONLY" # 我們要用手動指定的 IP
  nat_ips                = [google_compute_address.nat_ip.self_link]

  # 指定在哪個子網生效 (我們只讓私有子網能上網)
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.bff_subnet.id #讓bff連公開網路
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]                       # subnet中的所有網段都可以連
  }
  subnetwork {
    name                    = google_compute_subnetwork.connector_subnet.id #讓爬蟲透過 connector 也能連外
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
