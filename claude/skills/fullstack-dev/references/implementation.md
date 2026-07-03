# 実装規約

どのスタックでも共通の原則と、Next.js(デフォルト構成)での具体形を示す。
別スタックの場合は原則の方を優先し、具体形はそのスタックの慣習に読み替える。

## ディレクトリ構成(Next.js)

```
src/
├── middleware.ts     # ルート保護(認証がある場合。admin-user-patterns.md参照)
├── app/              # ルーティング(ページ + API)
│   ├── (public)/     # 未ログイン画面(login等)※認証がある場合
│   ├── (user)/       # ユーザー画面
│   ├── (admin)/admin/ # 管理画面(/admin配下に統一)※管理画面がある場合
│   └── api/          # APIルート
├── components/       # UIコンポーネント
├── lib/              # 共有ロジック
│   ├── db.ts         # Prismaクライアント(シングルトン)
│   ├── auth.ts       # 認証ヘルパー
│   └── validators/   # Zodスキーマ(API/フォームで共用)
├── services/         # ビジネスロジック(APIルートから呼ぶ)
└── types/
```

**APIルートにビジネスロジックを書かない。** ルートは「認証確認 → バリデーション →
service呼び出し → レスポンス整形」だけにする。ロジックがserviceにあれば
テストがHTTP抜きで書け、フロントのServer Actionからも再利用できる。

## バリデーション

- 境界(APIの入口)で必ず検証する。フロントのバリデーションは UX のためであり、防御にはならない
- Zodスキーマを `lib/validators/` に置き、API とフォームの両方から import する

```typescript
// lib/validators/reservation.ts
export const createReservationSchema = z.object({
  roomId: z.string().cuid(),
  startsAt: z.coerce.date(),
  endsAt: z.coerce.date(),
}).refine(d => d.endsAt > d.startsAt, { message: "終了は開始より後" });
```

## エラーハンドリング

- 予期されるエラー(バリデーション、認可、業務ルール違反)は専用のエラークラスで表現し、
  APIレイヤーで対応するHTTPステータスに変換する
- 予期しないエラーは 500 + 汎用メッセージ。**内部詳細(スタックトレース、SQL)を
  レスポンスに含めない**。ログにのみ出す

```typescript
// lib/errors.ts
export class AppError extends Error {
  constructor(public code: string, message: string, public status: number) {
    super(message);
  }
}
// 使用: throw new AppError("RESERVATION_CONFLICT", "時間帯が重複しています", 409);
```

## 認証・認可

- セッション管理は Auth.js、またはシンプルな要件なら httpOnly Cookie + JWT
- **トークンを localStorage に置かない**(XSSで抜かれる)
- 認可チェックは service 層でも行う(APIルートだけに置くと、別ルートから
  service を呼んだとき素通りする)
- パスワードは bcrypt / argon2。自前ハッシュ禁止

## フロントエンド

- データ取得は Server Component を基本にし、インタラクティブな部分だけ Client Component
- フォームは Server Action + Zod(APIと同じスキーマ)
- ローディング・エラー・空状態の3状態を必ず作る。正常系だけの画面は未完成とみなす

## その他の規約

- 環境変数は起動時に検証する(Zodで `env.ts` を作る)。実行時に `undefined` で落ちるのを防ぐ
- 秘密情報をコミットしない。`.env` は .gitignore、`.env.example` に鍵名のみ列挙
- DBアクセスはトランザクション境界を意識する。複数書き込みが伴う操作は `$transaction` で包む
