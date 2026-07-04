
## 4. 実装タスクの進め方

実装は `tasks/NNN-*.md` の指示書単位で進める(1タスク = 1ファイル。地図は
`docs/ai/INDEX.md`)。実装セッションは次を守ること:

- 着手時にタスクファイルの `status` を `in-progress` に、完了時に `done` に更新する
- 合意済みの設計(`docs/requirements.md` / `docs/schema.md` / `docs/api.md` /
  `docs/rbac.md`)を勝手に変えない。不備を見つけたらタスクファイルに報告を書き、
  ユーザーの判断を仰ぐ
- 各段階で動作確認してから次へ進む。全部書いてから一気に動かさない
- 実装規約は `docs/ai/references/` の implementation.md / test-deploy.md
  (あれば admin-user-patterns.md)に従う。コードを書く前に読む
- 完了時はタスクファイル末尾に完了報告(実装内容 / 判断した点 / 詰まった点)を
  追記し、`docs/ai/STATUS.md` を更新する。「判断した点」はユーザーが承認したら
  `docs/ai/decisions/` に記録する
- 設計変更が承認されたら、`docs/schema.md` などの設計ドキュメントも併せて更新し、
  常に「現在の姿」を保つ
