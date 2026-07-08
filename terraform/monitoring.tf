# D26: Logging & Monitoring
# 追蹤對話成功率（BFF 層）與 Token 消耗量（CES 平台層）
#
# 「成功率」拆成兩層互補的指標：
#   1. CES Agent Studio 內建 Dashboard（console 原生功能，非 Cloud Monitoring metric）
#      看的是「Agent 有沒有答對問題」(Conversation Outcomes / Escalation Rate)
#   2. 這裡的 log-based metric 看的是「BFF 這層的可用性」
#      (認證失敗、rate limit、逾時、WebSocket 斷線等 Agent 平台看不到的失敗)
# Token 消耗量直接讀 CES 平台原生 metric（ces.googleapis.com/app/token_consumption_count），
# 不用在 BFF 自行解析 API response —— RunSessionResponse 本身沒有 usageMetadata 欄位。

# ─── Log-based Metrics（來源：bff/main.py 的 _audit() 結構化 log）───────────────

resource "google_logging_metric" "bff_request_success" {
  name   = "bff_request_success_count"
  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.bff_service.name}"
    (jsonPayload.event="query_success" OR jsonPayload.event="stream_success")
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "bff_request_failure" {
  name   = "bff_request_failure_count"
  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.bff_service.name}"
    (jsonPayload.event="query_failed" OR jsonPayload.event="stream_failed")
  EOT

  label_extractors = {
    "reason" = "EXTRACT(jsonPayload.reason)"
  }

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key = "reason"
    }
  }
}

resource "google_logging_metric" "bff_request_latency" {
  name            = "bff_request_latency_ms"
  filter          = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.bff_service.name}"
    jsonPayload.latency_ms>=0
  EOT
  value_extractor = "EXTRACT(jsonPayload.latency_ms)"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "ms"
  }

  bucket_options {
    exponential_buckets {
      num_finite_buckets = 30
      growth_factor      = 1.5
      scale              = 10
    }
  }
}

# ─── Dashboard：BFF 可用性 + CES Token 消耗量 ─────────────────────────────────

resource "google_monitoring_dashboard" "bank_ai_overview" {
  dashboard_json = jsonencode({
    displayName = "Bank AI - D26 對話監控"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width = 6, height = 4, xPos = 0, yPos = 0
          widget = {
            title = "BFF 成功 / 失敗次數"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter      = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.bff_request_success.name}\" resource.type=\"cloud_run_revision\""
                      aggregation = { alignmentPeriod = "300s", perSeriesAligner = "ALIGN_RATE" }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "success"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter      = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.bff_request_failure.name}\" resource.type=\"cloud_run_revision\""
                      aggregation = { alignmentPeriod = "300s", perSeriesAligner = "ALIGN_RATE" }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "failure"
                },
              ]
            }
          }
        },
        {
          width = 6, height = 4, xPos = 6, yPos = 0
          widget = {
            title = "BFF Latency (P50 / P99, ms)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter      = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.bff_request_latency.name}\" resource.type=\"cloud_run_revision\""
                      aggregation = { alignmentPeriod = "300s", perSeriesAligner = "ALIGN_PERCENTILE_50" }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p50"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter      = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.bff_request_latency.name}\" resource.type=\"cloud_run_revision\""
                      aggregation = { alignmentPeriod = "300s", perSeriesAligner = "ALIGN_PERCENTILE_99" }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p99"
                },
              ]
            }
          }
        },
        {
          width = 6, height = 4, xPos = 0, yPos = 4
          widget = {
            title = "CES Token 消耗量"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter      = "metric.type=\"ces.googleapis.com/app/token_consumption_count\" resource.type=\"ces.googleapis.com/App\""
                      aggregation = { alignmentPeriod = "3600s", perSeriesAligner = "ALIGN_SUM" }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "tokens/hr"
                },
              ]
            }
          }
        },
        {
          width = 6, height = 4, xPos = 6, yPos = 4
          widget = {
            title = "CES 對話數 (session_count)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter      = "metric.type=\"ces.googleapis.com/app/session_count\" resource.type=\"ces.googleapis.com/App\""
                      aggregation = { alignmentPeriod = "3600s", perSeriesAligner = "ALIGN_SUM" }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "sessions/hr"
                },
              ]
            }
          }
        },
      ]
    }
  })
}
