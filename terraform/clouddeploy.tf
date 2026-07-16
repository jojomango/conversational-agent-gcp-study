# D28: Cloud Deploy — release/xxx CI 之後，真正部署到 prod 的關卡
#
# 只有 prod_project_id 有填值時才建立;目前沒有真正的 prod project(見 env/dev.mk 註解),
# 這裡全部是示意用途,不會被 apply。
#
# cloudbuild-release.yaml 建立 release 後,Cloud Deploy 會依 serial_pipeline 的順序
# 嘗試 rollout 到 prod target;因為 prod target 設了 require_approval,rollout 會停在
# PENDING_APPROVAL,需要有人在 Console 或用
#   gcloud deploy rollouts approve <rollout-id> --release=<release> --delivery-pipeline=...
# 手動核准後才會真的部署——approve 這個動作本身就是觸發部署,不需要再手動跑一次 trigger。

resource "google_clouddeploy_delivery_pipeline" "bff_release" {
  count    = var.prod_project_id != "" ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = "bank-bff-release-pipeline"

  serial_pipeline {
    stages {
      target_id = google_clouddeploy_target.prod[0].target_id
    }
  }
}

resource "google_clouddeploy_target" "prod" {
  count    = var.prod_project_id != "" ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = "prod"

  require_approval = true

  run {
    location = "projects/${var.prod_project_id}/locations/${var.prod_region != "" ? var.prod_region : var.region}"
  }
}

# 注意（跨 project 權限,無法在此完整示意）：
# Cloud Deploy 實際部署到 prod target 時,是用「執行服務帳號」去呼叫 prod project 的
# Cloud Run API,預設會是本 project 的 Compute Engine 預設 SA,且必須額外被授權
# prod project 的 roles/run.admin、roles/iam.serviceAccountUser。
# 因為 prod project 目前不存在,這一步無法在這裡用 google_project_iam_member 示範
# （會需要對一個不存在的 project 呼叫 IAM API);真的建立 prod project 後,
# 需要另外對 prod project 補上這組跨 project IAM 授權,或改用 execution_configs
# 指定專用的 service account。
