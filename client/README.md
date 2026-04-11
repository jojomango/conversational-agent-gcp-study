# 🖥 Client — 前端使用者介面

## 本地開發設定

Firebase Google Sign-In **不允許 `file://` 協定**，必須透過 HTTP 提供頁面：

```bash
# 在專案根目錄執行
python3 -m http.server 5500 --directory client
```

接著用瀏覽器開啟 [http://localhost:5500](http://localhost:5500)。

> `localhost:5500` 已預設在 BFF 的 `ALLOWED_ORIGINS` 白名單中。
> BFF 也需同時在 `localhost:8080` 運行（見 bff/README.md）。

## 功能說明

目前 `client/` 是一個 D14 測試頁，供本地驗證 Firebase Login、ID Token 取得與 BFF `/query` 串接。
正式的產品化前端 UI 尚未開始實作。

## 資料流

```
使用者輸入 → Client → HTTP Request → BFF → Agent → Cloud SQL
                ←─────────────────────────── AI 回答
```

## 當前實作

- 單檔 `index.html` 測試頁
- 使用 Firebase Web SDK（CDN compat 版）
- 透過 `config.js` 載入 Firebase 設定
- 可直接帶著 ID Token 呼叫 BFF `/query`

## 技術選型（後續）

暫定選項：
- **Vue.js / React**：SPA，部署於 Cloud Run
- **Firebase Hosting**：靜態部署（與 Firebase Auth 整合）

## GCP 對應服務

| 功能 | GCP 服務 |
|------|---------|
| 部署 | Cloud Run 或 Firebase Hosting |
| 身分驗證 | Firebase Auth → ID Token → BFF |

## Auth 流程（D14 已可本地驗證）

```
1. 使用者在 Client 用 Firebase Login
2. Client 取得 Google ID Token
3. Client 帶著 Token 送請求到 BFF
4. BFF 驗證 Token（IAM Auth）
```

## 狀態

- [x] Firebase Auth 整合（D14 測試頁）
- [x] 取得 ID Token 並呼叫 BFF `/query`
- [ ] 正式前端框架選型（SPA / Hosting 策略）
- [ ] UI 設計與實作
- [ ] Cloud Run 部署設定

---
*Last Updated: 2026-04-11*
