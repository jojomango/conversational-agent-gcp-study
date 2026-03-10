import os
import json
import re
import time
import requests
from bs4 import BeautifulSoup, Tag
from google.cloud import storage
from datetime import datetime
from urllib.parse import urljoin
from dotenv import load_dotenv

# 載入 .env
load_dotenv()

# 配置區
TARGET_URL = "https://owasp.org/Top10/2025/"
LOCAL_DATA_PATH = "./data/raw"
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")


def _extract_section(soup, heading_keyword):
    """Extract cleaned text from an <h2> section until the next <h2>."""
    for h2 in soup.find_all('h2'):
        if heading_keyword.lower() in h2.get_text(strip=True).lower():
            parts = []
            for sibling in h2.find_next_siblings():
                if sibling.name == 'h2':
                    break
                if isinstance(sibling, Tag):
                    parts.append(sibling.get_text(separator='\n', strip=True))
            return '\n'.join(parts).strip()
    return ""


def scrape_detail(url):
    """Fetch and parse a single OWASP Top10 detail page."""
    response = requests.get(url)
    if response.status_code != 200:
        print(f"[!] Failed to fetch {url}: HTTP {response.status_code}")
        return {}

    soup = BeautifulSoup(response.text, 'html.parser')

    # CWE list extracted as structured list rather than raw text
    cwe_list = []
    for h2 in soup.find_all('h2'):
        if 'mapped cwe' in h2.get_text(strip=True).lower():
            for sibling in h2.find_next_siblings():
                if sibling.name == 'h2':
                    break
                for a_tag in sibling.find_all('a', href=re.compile(r'cwe\.mitre\.org')):
                    cwe_text = a_tag.get_text(strip=True)
                    if cwe_text:
                        cwe_list.append(cwe_text)
            break

    return {
        "background": _extract_section(soup, "background"),
        "description": _extract_section(soup, "description"),
        "how_to_prevent": _extract_section(soup, "how to prevent"),
        "example_scenarios": _extract_section(soup, "example attack scenarios"),
        "cwe_list": cwe_list,
    }


def scrape_owasp():
    print(f"[*] Starting scrape from {TARGET_URL}...")
    response = requests.get(TARGET_URL)
    soup = BeautifulSoup(response.text, 'html.parser')

    results = []
    # 根據 OWASP 2025 頁面結構抓取 A01-A10 標題與子頁面連結 (目前在 <a> 標籤內)
    items = soup.find_all(lambda tag: tag.name == 'a' and re.search(r'^A\d{2}', tag.text))

    seen_categories = set()
    for item in items:
        text = item.get_text(strip=True)
        # 支援 "A01 Broken Access Control" 或 "A01:2025 - Broken Access Control" 等格式
        match = re.search(r"^(A\d{2})[:\s-]*(\d{4})*[:\s-]*(.+)", text)
        if not match:
            continue

        category = match.group(1)
        clean_title = f"{category} {match.group(3).strip()}"

        if category in seen_categories:
            continue
        seen_categories.add(category)

        href = item.get('href', '')
        detail_url = urljoin(TARGET_URL, href)

        data_point = {
            "category": category,
            "title": clean_title,
            "detail_url": detail_url,
            "source": TARGET_URL,
            "scraped_at": datetime.utcnow().isoformat() + "Z"
        }
        results.append(data_point)

    # Phase 2: 逐一爬取每個 A0X 詳細頁面
    for i, entry in enumerate(results):
        print(f"[*] Fetching detail [{i+1}/{len(results)}]: {entry['detail_url']}")
        detail = scrape_detail(entry['detail_url'])
        entry.update(detail)
        time.sleep(1)

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