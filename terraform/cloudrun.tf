# 1. 定義 Cloud Run 服務 (BFF)
resource "google_cloud_run_v2_service" "bff_service" {
  name     = "chatbot-bff"
  location = "asia-east1"

  # 銀行級安全：只允許透過認證的請求 (取代 IAP 的方案)
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    # 連結我們 Day 5 做的 Service Account
    service_account = google_service_account.chatbot_bff_sa.email

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
