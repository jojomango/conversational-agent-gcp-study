# 🕷 Crawler

`crawler/` 會抓取 OWASP Top 10 內容，輸出 raw JSON 到本地 `data/raw/`，並在有設定 `GCS_BUCKET_NAME` 時同步上傳到 GCS。

## 本地開發

```bash
cd crawler
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 若要上傳到 GCS，需先完成 ADC 登入
gcloud auth application-default login

python main.py
```

## 輸出

- 本地備份：`crawler/data/raw/owasp_raw_YYYYMMDD.json`
- GCS：`gs://<bucket>/raw/owasp_raw_YYYYMMDD.json`

## 容器建置

本專案已改用 Artifact Registry，不再使用 GCR。

```bash
make build-push-crawler ENV=dev
```

若要在雲端執行，使用專案根目錄的 `make crawl-sync` 觸發 Cloud Run Job。

---
*Last Updated: 2026-04-11*

