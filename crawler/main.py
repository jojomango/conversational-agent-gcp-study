import os
import json
import re
import requests
from bs4 import BeautifulSoup
from google.cloud import storage
from datetime import datetime
from dotenv import load_dotenv

# 載入 .env
load_dotenv()

# 配置區
TARGET_URL = "https://owasp.org/Top10/2025/"
LOCAL_DATA_PATH = "./data/raw"
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")

def scrape_owasp():
    print(f"[*] Starting scrape from {TARGET_URL}...")
    response = requests.get(TARGET_URL)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    results = []
    # 根據 OWASP 2025 頁面結構抓取 A01-A10 標題 (目前在 <a> 標籤內)
    items = soup.find_all(lambda tag: tag.name == 'a' and re.search(r'^A\d{2}', tag.text))

    seen_categories = set()
    for item in items:
        text = item.get_text(strip=True)
        # 提取 Metadata 類別 (例如: A01)
        # 支援 "A01 Broken Access Control" 或 "A01:2025 - Broken Access Control" 等格式
        match = re.search(r"^(A\d{2})[:\s-]*(\d{4})*[:\s-]*(.+)", text)
        if not match:
            continue
            
        category = match.group(1)
        # 清理多餘的年份與符號，只留下真正標題 (例如 Broken Access Control)
        clean_title = f"{category} {match.group(3).strip()}"
        
        if category in seen_categories:
            continue
        seen_categories.add(category)
        
        data_point = {
            "category": category,
            "title": clean_title,
            "source": TARGET_URL,
            "scraped_at": datetime.utcnow().isoformat() + "Z"
        }
        results.append(data_point)
    
    return results

def save_to_local(data):
    if not os.path.exists(LOCAL_DATA_PATH):
        os.makedirs(LOCAL_DATA_PATH)
    
    filename = f"owasp_raw_{datetime.now().strftime('%Y%m%d')}.json"
    filepath = os.path.join(LOCAL_DATA_PATH, filename)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"[V] Local backup saved: {filepath}")
    return filepath, filename

def upload_to_gcs(local_path, destination_blob_name):
    if not BUCKET_NAME:
        print("[!] GCS_BUCKET_NAME not set, skipping cloud upload.")
        return
    
    storage_client = storage.Client()
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(f"raw/{destination_blob_name}")
    
    blob.upload_from_filename(local_path)
    print(f"[V] Cloud upload success: gs://{BUCKET_NAME}/raw/{destination_blob_name}")

if __name__ == "__main__":
    scraped_data = scrape_owasp()
    if scraped_data:
        local_file, file_name = save_to_local(scraped_data)
        upload_to_gcs(local_file, file_name)
    else:
        print("[X] No data found.")