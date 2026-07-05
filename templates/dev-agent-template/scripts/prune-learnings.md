# learnings 棚卸し手順(月次実行)

これはスクリプトではなく、Claude Code等のエージェントに月次で実行させるための指示書です。
cronから以下のようにClaude Codeのheadlessモードで呼び出すことを想定しています。

```bash
# 例(フラグ名はお使いのClaude Codeのバージョンで `claude --help` を確認して調整してください)
cd /path/to/repo && claude -p "$(cat scripts/prune-learnings.md)"
```

## 実行内容

1. `.claude/skills/*/learnings/` 配下の全エントリ(README.md以外)を読み込む
2. 各Skillの learnings/ について以下を行う:
   - 内容が重複しているエントリを1つに統合する(統合後、古い方のファイルは削除)
   - 矛盾している記述があれば、より新しい `date:` のものを優先して古い方を削除する
   - `date:` が3ヶ月以上前で、かつ以降のコミット履歴からそのパターンの再発がないものは
     同Skillの `learnings/archive/` に移動する
   - frontmatterの `kind: rule` / `kind: tip` が未設定のエントリには適切な方を設定する
3. 変更は**ブランチを切ってPRとして提出する**(mainに直接コミットしない。
   AGENTS.md 7節の通り、learningsのmain反映はscribeまたは人間のレビューを経ること)
   - ブランチ名: `chore/prune-learnings-YYYY-MM`
   - PRタイトル: `chore: prune learnings (monthly review)`
   - PR本文に変更点の要約(統合・削除・アーカイブしたエントリの一覧と理由)を書く

## 注意事項

- SKILL.md本体(手順書)と learnings/README.md(書式定義)は書き換えないこと
- 迷った場合は削除せず残す(誤って有用な知見を消すリスクの方が高い)
- この作業自体もAGENTS.md 6節のエスカレーション条件に従う(SKILL.md本体の変更が
  必要だと感じた場合は、PRではなくIssueを立てて人間に提案する)
