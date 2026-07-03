# テスト・デプロイガイド

## テスト方針

網羅率より「壊れたらすぐ気づける主要経路」を優先する。優先順位:

1. **ビジネスロジック(services/)のユニットテスト** — 一番安く、一番壊れやすい所
2. **主要APIの結合テスト** — 正常系 + 認可エラー(401/403) + バリデーションエラー(400)の3点セット
3. E2E は主要フロー1〜2本だけ(必要な場合のみ。Playwright)

### 規約

- テストは実装と同じPRで書く。「後でまとめて」は書かれない
- DBを使うテストはテスト用DB(SQLite in-memory か Docker の使い捨てPostgres)で。モックだらけの結合テストは結合をテストしていない
- テストデータはファクトリ関数で作る(`createTestUser(overrides)`)。フィクスチャの共有はテスト間の依存を生むため避ける

```typescript
// 結合テストの型: 正常系 + 認可 + バリデーション
describe("POST /api/reservations", () => {
  it("creates a reservation", async () => { /* 201 */ });
  it("rejects unauthenticated requests", async () => { /* 401 */ });
  it("rejects overlapping time ranges", async () => { /* 409 */ });
  it("rejects endsAt before startsAt", async () => { /* 400 */ });
});
```

## デプロイ

どの環境でも共通の成果物:

- **`.env.example`** — 必要な環境変数を全部列挙(値はダミーか説明)
- **README** — セットアップ手順(clone → install → migrate → dev が3コマンド以内)+ デプロイ手順
- デプロイ先の選定理由が Decision Record にあること

### 環境別の手順・注意点

**Vercel**
- Next.jsならリポジトリ接続のみ。環境変数はダッシュボードで設定
- DBは Neon / Supabase / PlanetScale 等のマネージドを使う。接続はプーリング必須(サーバーレスは接続数が爆発する)
- ビルド時に `prisma generate` が走るよう postinstall に入れる

**Cloudflare (Workers / Pages)**
- デプロイ前に必ずローカルで `wrangler dev` により Workers ランタイムで動作確認(Node開発サーバーで動いてもWorkersで動くとは限らない)
- DB: D1(SQLite系)+ Drizzle が素直。外部Postgresなら Hyperdrive 経由
- 環境変数は `wrangler secret put`。`.dev.vars` をローカル用に(gitignore)

**VPS**
- Docker Compose(app + db + Caddy)を標準形にする。Caddyは自動TLSでリバースプロキシ設定が数行で済む
- `docker compose up -d` で全部起動する状態にする。ホストに直接 node を入れない
- 最低限の運用: DBの日次バックアップ(cron + pg_dump)、自動再起動(restart: always)
- ファイアウォールで公開ポートは 80/443 のみに絞る

**クラウド (Cloud Run / App Runner 等)**
- Dockerfile があれば載る。下記のマルチステージビルドを使う
- DBはマネージド(Cloud SQL / RDS)。接続情報はシークレットマネージャ経由

### Dockerfile の型(Next.js — VPS/クラウド共通)

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci
COPY . .
RUN npx prisma generate && npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]
```

(`next.config.js` に `output: "standalone"` が必要。`prisma/` を `npm ci` より先に
コピーするのは、postinstall に `prisma generate` を入れた構成でもビルドが落ちないようにするため)

### マイグレーション

- 本番反映は `prisma migrate deploy`(`db push` は開発専用。本番で使うと履歴が壊れる)
- マイグレーションはロールバック手順も考えてから流す。破壊的変更(カラム削除等)は
  「追加 → 移行 → 削除」の2段階デプロイに分ける

### CI(GitHub Actions の最小形)

push 時に lint + typecheck + test を回す。デプロイ自動化は要件次第でよいが、
テストが CI で回っていない状態を「完成」と呼ばない。
