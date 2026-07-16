# D28: CI/CD — Cloud Build triggers
#
# 對應 git flow：
#   - main            → 不建立任何 trigger（純歷史紀錄 / hotfix 起點,不觸發部署)
#   - staging         → 情境一 (Continuous Deployment)：push 自動 build + 直接部署到本 project
#   - release/xxx     → 情境二 (Continuous Delivery)：push 自動 build + push image,
#                        真正的部署交給 Cloud Deploy 的 approval 關卡（見 clouddeploy.tf)
#
# 這個 repo 目前是純本地 repo,還沒推上 GitHub,Cloud Build 的 GitHub 連線也需要先在
# Console 完成一次性的 GitHub App 安裝授權（無法單靠 Terraform 自動化)。
# 所以這裡用 github_owner / github_repo_name 是否為空做條件式建立,預設全部跳過,
# 不影響現有 `make up` 的行為;真的要啟用時,把這兩個變數填上 GitHub owner/repo 名稱即可。

variable "github_owner" {
  description = "GitHub 帳號或組織名稱。留空時 Cloud Build trigger 全部跳過（示意用,本 repo 目前無 GitHub remote）"
  type        = string
  default     = ""
}

variable "github_repo_name" {
  description = "GitHub repo 名稱（不含 owner）"
  type        = string
  default     = ""
}

locals {
  cicd_enabled = var.github_owner != "" && var.github_repo_name != ""
  # Cloud Build 預設服務帳號（legacy 格式）
  cloudbuild_sa = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# staging：push 就自動 build + deploy,沒有 approval 關卡
resource "google_cloudbuild_trigger" "staging" {
  count       = local.cicd_enabled ? 1 : 0
  project     = var.project_id
  location    = var.region
  name        = "bff-staging-deploy"
  description = "D28: staging push 自動部署到驗證環境（情境一）"
  filename    = "cloudbuild-staging.yaml"

  github {
    owner = var.github_owner
    name  = var.github_repo_name
    push {
      branch = "^staging$"
    }
  }
}

# release/xxx：push 只自動跑 CI（build + push image),CD 由 Cloud Deploy 的
# prod target approval 關卡決定是否真正部署（見 clouddeploy.tf)
resource "google_cloudbuild_trigger" "release" {
  count       = local.cicd_enabled ? 1 : 0
  project     = var.project_id
  location    = var.region
  name        = "bff-release-ci"
  description = "D28: release/* push 自動 CI,CD 交給 Cloud Deploy approval（情境二）"
  filename    = "cloudbuild-release.yaml"

  github {
    owner = var.github_owner
    name  = var.github_repo_name
    push {
      branch = "^release/.+$"
    }
  }
}

# 讓 Cloud Build 預設 SA 有權限：push image、部署 staging、建立 Cloud Deploy release
resource "google_project_iam_member" "cloudbuild_ar_writer" {
  count   = local.cicd_enabled ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = local.cloudbuild_sa
}

resource "google_project_iam_member" "cloudbuild_run_admin" {
  count   = local.cicd_enabled ? 1 : 0
  project = var.project_id
  role    = "roles/run.admin"
  member  = local.cloudbuild_sa
}

resource "google_project_iam_member" "cloudbuild_sa_user" {
  count   = local.cicd_enabled ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = local.cloudbuild_sa
}

resource "google_project_iam_member" "cloudbuild_clouddeploy_releaser" {
  count   = local.cicd_enabled ? 1 : 0
  project = var.project_id
  role    = "roles/clouddeploy.releaser"
  member  = local.cloudbuild_sa
}
