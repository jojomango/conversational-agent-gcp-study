# ==========================================
# Secret Manager — 安全儲存敏感資訊
# ==========================================
# D17: 原本計劃將敏感資訊存入 Secret Manager。
# D17+: 改用 Terraform Variable 傳遞配置（CES 憑證非真正的密碼）。
# 
# 保留此檔案作為未來需要真正密碼管理時的參考（例如 API Keys）。

# 1. 資料庫密碼
# [COMMENTED OUT - D17+]
# 原因：專案改用 CX Agent Studio，不需要自建資料庫。
# 若未來啟用 database.tf，取消下方註解。
# resource "google_secret_manager_secret" "db_password" {
#   secret_id = "db-password"
#   replication {
#     auto {}
#   }
# }

# 2-3. CX Agent 憑證
# [REMOVED - D17+]
# 原因：ces_app_name 和 ces_deployment_name 改用 Terraform Variable。
# 這些只是配置資訊（類似 FIREBASE_PROJECT_ID），不是密碼，不需 Secret Manager。

# ==========================================
# Secret 值建立指令（未來參考）
# ==========================================
# 若未來需要使用 Secret Manager（例如真正的 API Keys），參考以下指令：
#
# echo -n "your-secret-value" | gcloud secrets versions add secret-name --data-file=-
# gcloud secrets versions list secret-name
