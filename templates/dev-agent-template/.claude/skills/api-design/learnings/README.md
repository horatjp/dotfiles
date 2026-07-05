# learnings — 学びの蓄積(api-design)

蓄積する内容: このプロジェクト特有のAPI設計の落とし穴

## ルール(単一ファイル追記は禁止)

- **1エントリ = 1ファイル**。ファイル名は `YYYY-MM-DD-<slug>.md`(例: `2026-07-05-async-cleanup-leak.md`)
- 理由: 複数エージェントが並列worktreeで同じファイルに追記するとmerge conflictが必ず起きるため
- mainへの反映は必ずPR経由。scribe(または人間)がレビューしてからマージする
- 読む側(次のbuilder/verifier)は `kind: rule` のエントリを必読、`kind: tip` は参考程度でよい

## エントリの書式

```markdown
---
date: YYYY-MM-DD
kind: rule   # rule = 絶対守るべきルール / tip = 参考程度のTips
issue: "#123"  # きっかけになったIssue/PR(あれば)
---

具体的な事象と、再発防止の観点を簡潔に書く。
```

月次で棚卸しを行う(手順: `scripts/prune-learnings.md`)。3ヶ月再発のないエントリは
`archive/` サブディレクトリへ移動する。
