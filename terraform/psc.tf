# D25: Private Service Connect (PSC) — 私有存取 Google APIs (Vertex AI 等)
#
# D24 的 VPC Service Controls 只解決「誰有權限打這些 API」(identity perimeter)，
# 但 BFF (egress = ALL_TRAFFIC，見 cloudrun.tf) 呼叫 aiplatform.googleapis.com 時，
# 封包仍會被 Cloud NAT 轉出去打 Google 的「公開 API IP」，走的是 public routing path。
#
# D25 在 VPC 內建立一個內部 IP 端點，讓 *.googleapis.com 解析到這個私有 IP，
# 使 Vertex AI / GCS / Cloud SQL Admin / Secret Manager 的呼叫完全走 VPC 內部，
# 不再依賴 Cloud NAT 出網。搭配 D24 的 Service Perimeter，形成「network + identity」雙重邊界。
#
# 前置條件：需先啟用 `dns.googleapis.com`（Cloud DNS API）。

# 1. PSC Endpoint 用的內部 IP（global，位址需避開 bff-subnet 10.0.1.0/24
#    與 connector-subnet 10.8.0.0/28 已使用的範圍）
resource "google_compute_global_address" "psc_googleapis_ip" {
  name         = "psc-googleapis-ip"
  address_type = "INTERNAL"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network      = google_compute_network.main_vpc.id
  address      = "10.10.10.10"
}

# 2. PSC Endpoint 本體
#    target = "vpc-sc"：對應受 VPC Service Controls 保護的 API 集合
#    （與 vpc_sc.tf 的 restricted_services 搭配使用，等同私有版的 restricted.googleapis.com）
resource "google_compute_global_forwarding_rule" "psc_googleapis_endpoint" {
  name                  = "psc-googleapis-endpoint"
  target                = "vpc-sc"
  network               = google_compute_network.main_vpc.id
  ip_address            = google_compute_global_address.psc_googleapis_ip.id
  load_balancing_scheme = ""
}

# 3. 私有 DNS Zone：把 *.googleapis.com 導向上面的內部 IP
#    Cloud Run 的 VPC Connector 在 egress = ALL_TRAFFIC 時會使用綁定到這個 VPC 的
#    私有 DNS zone 解析，因此 BFF 呼叫 aiplatform.googleapis.com 會自動解到私有 IP。
resource "google_dns_managed_zone" "psc_googleapis_zone" {
  name       = "psc-googleapis-zone"
  dns_name   = "googleapis.com."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main_vpc.id
    }
  }
}

resource "google_dns_record_set" "psc_googleapis_cname" {
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.psc_googleapis_zone.name
  rrdatas      = ["googleapis.com."]
}

resource "google_dns_record_set" "psc_googleapis_a" {
  name         = "googleapis.com."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.psc_googleapis_zone.name
  rrdatas      = [google_compute_global_address.psc_googleapis_ip.address]
}
