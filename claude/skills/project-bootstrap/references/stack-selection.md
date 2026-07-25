# スタック選定ガイド

要件に合わせてスタックを選ぶ。決め手がなければデフォルト構成を使う。
「新しくて面白い技術」より「情報が多く詰まりにくい技術」を優先する —
このスキルの利用者は動くシステムが欲しいのであって、技術検証がしたいわけではない。

## デフォルト構成(迷ったらこれ)

| レイヤー | 技術 | 理由 |
|---|---|---|
| フレームワーク | Next.js (App Router) + TypeScript | フロント/APIを1リポジトリで完結。型を全レイヤーで共有できる |
| ORM | Prisma | スキーマがドキュメントを兼ねる。マイグレーション管理が容易 |
| DB | PostgreSQL(開発はSQLiteでも可) | 実運用への移行が容易 |
| バリデーション | Zod | APIとフォームで同じスキーマを使い回せる |
| 認証 | Auth.js / Clerk / Supabase Auth | 下記「認証の選び方」参照 |
| UI | Tailwind CSS(+ 管理画面があるなら shadcn/ui) | 管理画面のテーブル・フォーム・ダイアログ部品が揃う |
| テーブル/チャート | TanStack Table / Recharts | 管理画面・ダッシュボードがある場合のみ |
| テスト | Vitest + Testing Library | 高速。Next.jsとの相性が良い |

## 認証の選び方

| 状況 | 推奨 | 理由 |
|---|---|---|
| デフォルト / 自前DBでユーザー管理したい | Auth.js (NextAuth) v5 | 無料・自己完結。Credentials + OAuth両対応 |
| とにかく早く出したい、ユーザー管理UIも欲しい | Clerk | 組み込みUI・組織/ロール機能つき。ユーザー数課金に注意 |
| DBをSupabaseにする場合 | Supabase Auth | RLSと統合でき認可がDB層でも効く |

どれを選んでも、**ロール(role)はアプリのDBに持つ**。認証プロバイダ側の
metadata だけに置くと、JOINできず一覧・集計で詰む。

## デフォルトから外れる判断基準

| 状況 | 推奨 |
|---|---|
| チームがPHP資産を持つ / 指定あり | Laravel + Inertia (Vue/React) |
| リアルタイム性が主要件(チャット、通知) | Node/Express or NestJS + WebSocket、フロント分離 |
| 重い計算・ML連携がバックエンドにある | FastAPI (Python) + React分離構成 |
| 静的中心で一部動的 | Astro + APIルート |
| モバイルアプリが将来確実 | API分離構成(NestJS/FastAPI)にしてフロントを差し替え可能に |

## 分離構成 vs 一体型

- **一体型(Next.js等)**: 小〜中規模、開発者が少ない、素早く出したい → 基本これ
- **分離構成(SPA + API)**: チームが分かれる、API を複数クライアントが使う、
  バックエンドの言語要件がある場合のみ

分離構成はCORS・認証・デプロイの手間が倍になる。必要になってから分離する方が安い。

## デプロイ先の選び方(スタックと同時に決める)

デプロイ先の制約はスタック選定を左右する。後から変えると高くつくので同時に決める。

| デプロイ先 | 向いている状況 | スタックへの影響・注意 |
|---|---|---|
| **Vercel** | Next.js、素早く出したい、運用したくない | Next.jsなら設定ほぼ不要。DBは別途(Neon/Supabase等)。サーバーレスなので常駐処理・WebSocket不可 |
| **Cloudflare** (Workers/Pages) | エッジ配信、低コスト、グローバル | **制約が最も強い**: Node API非互換あり。ORMは Drizzle + D1 か Prisma driver adapter。重い処理・長時間実行不可。選ぶ前に依存の互換性を確認 |
| **VPS** (さくら/Linode/Hetzner等) | 常駐処理・WebSocket・cron が要る、コスト固定にしたい、データを自分で持ちたい | 制約なし。Docker Compose + Caddy(自動TLS)を標準形に。バックアップ・監視は自前 |
| **クラウド** (AWS/GCP コンテナ系) | 組織の指定、スケール要件、他マネージドサービスとの連携 | Cloud Run / App Runner ならDockerfileがあれば載る。IAM等のセットアップコストは高め |

判断の目安: 指定がなければ **Next.js → Vercel、常駐が要るなら VPS**。
Cloudflareは要件がエッジに合うときだけ選ぶ(互換性調査コストを払う価値があるか考える)。

## 選定結果の記録

選定結果は `docs/requirements.md` に1〜2行で記録する:

> スタック: Next.js + Prisma + PostgreSQL、デプロイ先: Vercel + Neon。単一チーム・中規模CRUD・常駐処理なしのため。

選定理由(候補・比較・決め手)は `docs/decisions/` に必ず記録する
(書式は `docs/decisions/_template.md`。下地展開前に決めた場合は、展開時にまとめて書く)。
