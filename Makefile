# 指向你的 terraform 檔案夾路徑
TF_DIR=terraform
DATA_TF_DIR=terraform-data
INSTANCE_TARGET=google_sql_database_instance.postgres_instance
PROJECT_ID?=your-gcp-project-id
REGION?=asia-east1
CRAWLER_JOB?=bank-crawler-job
VECTOR_JOB?=bank-vectorize-job
GCS_BUCKET?=

# 1. 啟動/部署全部資源
up:
	@echo "[INFO] Ensuring data state resources (GCS bucket) exist..."
	terraform -chdir=$(DATA_TF_DIR) apply -auto-approve
	@echo "[INFO] Detaching legacy bucket resources from infra state (if any)..."
	-terraform -chdir=$(TF_DIR) state rm google_storage_bucket.excel_storage
	-terraform -chdir=$(TF_DIR) state rm google_storage_bucket_iam_member.sa_storage_access
	@echo "[INFO] Applying infra state resources..."
	terraform -chdir=$(TF_DIR) apply -auto-approve

# 2. 僅關閉資料庫 (節省成本)
db-off:
	terraform -chdir=$(TF_DIR) destroy -target=$(INSTANCE_TARGET) -auto-approve

# 3. 重新開啟資料庫
db-on:
	terraform -chdir=$(TF_DIR) apply -target=$(INSTANCE_TARGET) -auto-approve

# 4. 全部刪除
# 注意：down 只刪 infra state；GCS bucket 由 terraform-data state 管理，會保留
down:
	@echo "[INFO] Destroying infra resources only; data state resources are preserved."
	terraform -chdir=$(TF_DIR) destroy -auto-approve
	@echo "[INFO] Done. GCS bucket remains managed by $(DATA_TF_DIR)."

# 5. 觸發雲端 crawler job，同步最新 raw 資料到 GCS
crawl-sync:
	@gcloud run jobs execute $(CRAWLER_JOB) --project=$(PROJECT_ID) --region=$(REGION) --wait

# 6. 將本地 crawler/raw 下的 JSON 上傳到 GCS (for 手動本地爬蟲)
sync-local-raw:
	@if [ -z "$(GCS_BUCKET)" ]; then \
		echo "[ERROR] GCS_BUCKET is empty. Usage: make sync-local-raw GCS_BUCKET=<bucket-name>"; \
		exit 1; \
	fi
	@gsutil -m cp crawler/data/raw/*.json gs://$(GCS_BUCKET)/raw/

# 7. 觸發向量化 job，從 GCS 讀取 raw 並寫入 Cloud SQL(pgvector)
reindex:
	@gcloud run jobs execute $(VECTOR_JOB) --project=$(PROJECT_ID) --region=$(REGION) --wait

# 8. 一鍵流程：先同步資料，再進行向量化
pipeline:
	@$(MAKE) crawl-sync PROJECT_ID=$(PROJECT_ID) REGION=$(REGION) CRAWLER_JOB=$(CRAWLER_JOB)
	@$(MAKE) reindex PROJECT_ID=$(PROJECT_ID) REGION=$(REGION) VECTOR_JOB=$(VECTOR_JOB)

# 9. 本地資料一鍵上傳+向量化
pipeline-local:
	@$(MAKE) sync-local-raw GCS_BUCKET=$(GCS_BUCKET)
	@$(MAKE) reindex PROJECT_ID=$(PROJECT_ID) REGION=$(REGION) VECTOR_JOB=$(VECTOR_JOB)