# 使用輕量級 Python 映像
FROM --platform=linux/amd64 python:3.11-slim

WORKDIR /app

# 安裝依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製代碼與建立地端資料夾
COPY main.py .
RUN mkdir -p /app/data/raw

# 執行爬蟲
CMD ["python", "main.py"]