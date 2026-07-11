# Environment variables template
# Copy this file to dev.mk or lab.mk and fill in the actual values.
# This file is committed to version control as a reference.

PROJECT_ID=your-gcp-project-id
REGION=asia-east1
CRAWLER_JOB=bank-crawler-job
VECTOR_JOB=bank-vectorize-job
GCS_BUCKET=bank-ai-excel-assets-$(PROJECT_ID)

# Firebase Auth project (可與 GCP PROJECT_ID 不同)
FIREBASE_PROJECT_ID=your-firebase-project-id

# CX Agent Studio (CES) — us region only
# 取得方式：CX Agent Studio > Deploy > Channel > 複製 Deployment ID
CES_APP_NAME=projects/YOUR_PROJECT_ID/locations/us/apps/YOUR_APP_ID
CES_DEPLOYMENT_NAME=projects/YOUR_PROJECT_ID/locations/us/apps/YOUR_APP_ID/deployments/YOUR_DEPLOYMENT_ID

# D27: Budget Alerts
# PROJECT_NUMBER 取得方式：gcloud projects list
# BILLING_ACCOUNT_ID 取得方式：gcloud beta billing accounts list（空白時 budget.tf 資源全部跳過）
PROJECT_NUMBER=your-project-number
BILLING_ACCOUNT_ID=
BUDGET_ALERT_EMAIL=your-alert-email@example.com
BUDGET_AMOUNT_TWD=1000
