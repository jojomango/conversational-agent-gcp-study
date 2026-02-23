# 指向你的 terraform 檔案夾路徑
TF_DIR=terraform
INSTANCE_TARGET=google_sql_database_instance.postgres_instance

# 1. 啟動/部署全部資源
up:
	terraform -chdir=$(TF_DIR) apply -auto-approve

# 2. 僅關閉資料庫 (節省成本)
db-off:
	terraform -chdir=$(TF_DIR) destroy -target=$(INSTANCE_TARGET) -auto-approve

# 3. 重新開啟資料庫
db-on:
	terraform -chdir=$(TF_DIR) apply -target=$(INSTANCE_TARGET) -auto-approve

# 4. 全部刪除
down:
	terraform -chdir=$(TF_DIR) destroy -auto-approve