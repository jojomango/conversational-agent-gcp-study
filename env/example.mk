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
