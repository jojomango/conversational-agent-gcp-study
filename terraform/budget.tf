# D27: Budget Alerts
# 監控每月 GCP 花費，達到門檻比例時通知，避免 Vertex AI / Cloud Run 等服務超支卻沒發現
#
# 前置條件：billing_account_id 空白時（例如公司 Lab 沒有帳務權限），以下資源全部跳過，make up 不受影響
# billing_account_id 取得方式：gcloud beta billing accounts list

# 1. Email 通知管道（budget_alert_email 空白時跳過；GCP 仍會用預設對象通知 Billing Account Admin/User）
resource "google_monitoring_notification_channel" "budget_email" {
  count        = var.billing_account_id != "" && var.budget_alert_email != "" ? 1 : 0
  display_name = "Bank AI Budget Alert Email"
  type         = "email"

  labels = {
    email_address = var.budget_alert_email
  }
}

# 2. 預算本體：以「本專案」為範圍（project_number 空白時退回整個 Billing Account 範圍）
resource "google_billing_budget" "bank_ai_budget" {
  count           = var.billing_account_id != "" ? 1 : 0
  billing_account = var.billing_account_id
  display_name    = "bank-ai-poc-monthly-budget"

  budget_filter {
    projects        = var.project_number != "" ? ["projects/${var.project_number}"] : null
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "TWD"
      units         = tostring(var.budget_amount_twd)
    }
  }

  # 50% / 80%：提早示警；100%：已達預算；120%：以「預估花費」提前示警可能超支
  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.8
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.2
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = var.budget_alert_email != "" ? [google_monitoring_notification_channel.budget_email[0].id] : []
    disable_default_iam_recipients   = false
  }
}
