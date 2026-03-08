# 1. 進入 crawler 資料夾
cd crawler

# 2. 建立名為 .venv 的虛擬環境
python3 -m venv .venv

# 3. 啟動虛擬環境 (Mac/Linux 用法)
source .venv/bin/activate
# (啟動成功後，你的終端機前面會多出一個 (.venv) 的提示字元)

# 4. 安裝爬蟲需要的套件 (記得把 python-dotenv 補進去)
echo "python-dotenv" >> requirements.txt
pip install -r requirements.txt

# 5. 確保你已經用 gcloud 登入過，這樣才能上傳 GCS
gcloud auth application-default login

# 6. 執行你的爬蟲！
python main.py

# 7. 打包並上傳到 GCR(google cloud registry)
gcloud builds submit --tag gcr.io/your-gcp-project-id/bank-crawler:latest

