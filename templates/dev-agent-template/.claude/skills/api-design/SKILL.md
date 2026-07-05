---
name: api-design
title: API設計担当
role: builder / planner
description: API(REST/RPC)の設計・命名規則・エラーハンドリング方針を定義する。
---

# api-design

## 使用タイミング
新しいエンドポイントの設計時、または既存APIの拡張時に参照する。

## 命名規則(プロジェクトに合わせて編集してください)

- リソース名は複数形の名詞(例: `/users`, `/orders`)
- 動詞をURLに含めない(`/getUser` ではなく `GET /users/:id`)
- ネストは2階層まで(`/users/:id/orders` はOK、`/users/:id/orders/:id/items/:id` はNG →
  別リソースとして切り出す)

## エラーハンドリング方針

- エラーレスポンスは統一フォーマットを使う:
  ```json
  { "error": { "code": "VALIDATION_ERROR", "message": "...", "field": "..." } }
  ```
- HTTPステータスコードは意味に沿って正しく使う(400/401/403/404/409/422/500の使い分けを徹底)
- 内部エラーの詳細(スタックトレース等)をレスポンスに含めない

## バージョニング

- 破壊的変更が必要な場合は `/v2/` のようにパスでバージョンを切る
- 既存クライアントへの影響がある変更は必ず `AGENTS.md` のエスカレーション条件に従い人間に確認する

## learnings/
実装時に発見した「このプロジェクト特有のAPI設計の落とし穴」を `learnings/` に
1エントリ1ファイルで追加していく(書式は `learnings/README.md` 参照)。
