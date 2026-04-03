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

使用者透過此介面輸入自然語言問題，查詢 OWASP 等安全規範知識庫。

## 資料流

```
使用者輸入 → Client → HTTP Request → BFF → Agent → Cloud SQL
                ←─────────────────────────── AI 回答
```

## 技術選型（待定）

暫定選項：
- **Vue.js / React**：SPA，部署於 Cloud Run
- **Firebase Hosting**：靜態部署（與 Firebase Auth 整合）

## GCP 對應服務

| 功能 | GCP 服務 |
|------|---------|
| 部署 | Cloud Run 或 Firebase Hosting |
| 身分驗證 | Firebase Auth → ID Token → BFF |

## Auth 流程（規劃中）

```
1. 使用者在 Client 用 Firebase Login
2. Client 取得 Google ID Token
3. Client 帶著 Token 送請求到 BFF
4. BFF 驗證 Token（IAM Auth）
```

## 狀態

- [ ] 框架選型（Day 12-13 前確認）
- [ ] Firebase Auth 整合（Day 12-13）
- [ ] UI 設計與實作（TBD）
- [ ] Cloud Run 部署設定

---
*Last Updated: 2026-02-19*
