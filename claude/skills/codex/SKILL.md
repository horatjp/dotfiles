---
name: codex
description: |
  Codex CLI（OpenAI）を使用してコードや文言について相談・レビューを行う。
  トリガー: "codex", "codexと相談", "codexに聞いて", "コードレビュー", "レビューして"
  使用場面: (1) 文言・メッセージの検討、(2) コードレビュー、(3) 設計の相談、(4) バグ調査、(5) 解消困難な問題の調査
---

# Codex CLI ヘルパー

このスキルは、Codex CLI（OpenAI）を使用して、コードや設計についてセカンドオピニオンを得たり、レビューを依頼したりするためのものです。

## 使用場面

1. **文言・メッセージの検討** - エラーメッセージやUIテキストの改善
2. **コードレビュー** - 実装のレビューや改善提案
3. **設計の相談** - アーキテクチャやAPI設計のアドバイス
4. **バグ調査** - 問題の原因特定や解決策の提案
5. **解消困難な問題の調査** - 複雑な問題への別視点からのアプローチ

## 実行方法

読み取りのみ（レビュー・調査）:

```bash
codex exec --sandbox read-only --skip-git-repo-check --cd "$PWD" "<リクエスト内容>"
```

ファイル書き込みあり（実装・修正）:

```bash
codex exec --sandbox workspace-write --skip-git-repo-check --cd "$PWD" "<リクエスト内容>"
```

## 使用例

### コードレビューを依頼

```bash
codex exec --sandbox read-only --skip-git-repo-check --cd "$PWD" "src/auth.tsのコードをレビューして、改善点があれば教えてください"
```

### 設計相談

```bash
codex exec --sandbox read-only --skip-git-repo-check --cd "$PWD" "認証システムをJWTからセッションベースに変更する場合の影響範囲を分析してください"
```

### バグ調査

```bash
codex exec --sandbox read-only --skip-git-repo-check --cd "$PWD" "ログイン時にセッションが維持されない問題の原因を調査してください"
```

## オプション

- `--sandbox read-only`: 読み取り専用（レビュー・調査向け）
- `--sandbox workspace-write`: ファイル書き込みあり（実装・修正向け）
- `--skip-git-repo-check`: trusted directory 外でも実行を許可
- `--cd <dir>`: 作業ディレクトリを指定

## 注意事項

- `read-only` モードではファイルの変更は行いません
- 結果はセカンドオピニオンとして参考にし、最終判断はユーザーが行ってください
- 長時間のタスクの場合、進捗が表示されます
