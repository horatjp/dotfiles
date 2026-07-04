# 管理画面 + ユーザー画面の実装パターン

**このファイルは管理画面・ロール分離があるシステムのときだけ読む。**
二面構成システムの骨格。ここを最初に固めると、以降の画面追加が全部この上に乗る。

## 画面分離: Route Groups + middleware

```
src/app/
├── (public)/          # 未ログインでも見える(LP、ログイン、登録)
│   ├── login/
│   └── register/
├── (user)/            # 一般ユーザー画面
│   ├── layout.tsx     # userナビゲーション付きレイアウト
│   └── ...
├── (admin)/admin/     # 管理画面(URLは /admin/... に統一)
│   ├── layout.tsx     # adminサイドバー付きレイアウト
│   ├── page.tsx       # ダッシュボード
│   └── ...
└── api/
```

URL設計は「管理画面は必ず `/admin` 配下」に統一する。middleware の保護ルールが
プレフィックス1つで書け、漏れが起きにくい。

## middleware によるルート保護

```typescript
// middleware.ts
export async function middleware(req: NextRequest) {
  const session = await getSessionFromRequest(req);
  const { pathname } = req.nextUrl;

  if (pathname.startsWith("/admin")) {
    if (!session) return NextResponse.redirect(new URL("/login", req.url));
    if (session.role !== "ADMIN")
      return NextResponse.redirect(new URL("/", req.url)); // 403ページでも可
  }
  // (user)配下: ログイン必須
  if (isProtectedUserPath(pathname) && !session)
    return NextResponse.redirect(new URL("/login", req.url));

  return NextResponse.next();
}
export const config = { matcher: ["/((?!_next|favicon.ico|api/auth).*)"] };
```

**middleware は第一防衛線であって唯一の防衛線ではない。** API・service 層でも
必ず認可チェックする(defense in depth)。middleware だけに頼ると、matcher の
書き漏れ1つで管理APIが素通りになる。

## 共通レイアウト

- **admin**: サイドバー(ナビ) + ヘッダー(ユーザーメニュー) + コンテンツ領域。
  ナビ項目は配列データで定義し、レイアウトはそれを map する(項目追加が1行で済む)
- **user**: ヘッダーナビ + コンテンツ。モバイル対応はこちらを優先(管理画面はPC前提でよいことが多い)
- ボタン・フォーム・テーブル等は shadcn/ui を使い、独自コンポーネントは
  `components/shared/`(両画面共通)、`components/admin/`、`components/user/` に分ける

## 管理画面の定番機能

### CRUDテーブル(管理画面の中心)

必須要素: ページネーション、検索/フィルタ、ソート、行アクション(編集/削除)。
実装は shadcn/ui の Table + TanStack Table が定番。
削除は必ず確認ダイアログを挟む。一覧のクエリはURLパラメータに載せる
(`?page=2&q=foo&sort=createdAt`)— リロード・共有で状態が復元できる。

### ダッシュボード

- KPIカード(件数・売上等の集計値)+ 時系列チャート1〜2枚から始める。作り込みすぎない
- チャートは Recharts。集計はDBで行う(`groupBy`)— 全件フェッチしてJSで集計しない
- 集計クエリは専用の service 関数に分離(ダッシュボードは重くなりがちで、後でキャッシュを挟む場所になる)

### ユーザー管理画面

admin配下に必ず置く機能: ユーザー一覧(検索付き)、ロール変更、無効化(BAN)。
物理削除より `isActive` フラグでの無効化を推奨(関連データの整合性が壊れない)。
**自分自身のロール降格・無効化は禁止する**(最後の管理者がいなくなる事故の防止)。

## シードデータ

開発開始時に必ず用意する:

```typescript
// prisma/seed.ts — 管理者1名 + 一般ユーザー1名 + ドメインデータ数件
```

管理者アカウントがシードされていないと、管理画面の動作確認が毎回手作業になる。
README にシードされる認証情報を明記する(例: admin@example.com / password123 — 開発専用と注記)。
