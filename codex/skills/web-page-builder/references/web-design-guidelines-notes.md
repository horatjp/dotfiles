# 取り込みメモ: vercel-labs/agent-skills @ web-design-guidelines

- 出典: https://github.com/vercel-labs/agent-skills （skills/web-design-guidelines、39行）
- 目的: UIコードをWeb Interface Guidelinesに照らしてレビューする（「review my UI」「check accessibility」等でトリガー）

## 良い点・転用ポイント

1. **ルール本体をリポジトリに置かず、毎回最新をfetchする設計**: `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md` をレビュー前に取得。スキル本体は手順だけ持ち、陳腐化しない
2. **出力形式を固定**: `file:line` の簡潔なフォーマットで指摘を列挙。レビュー結果の再現性が高い
3. **手順が4ステップで極小**: fetch → 対象ファイル読込 → 全ルール適用 → 指定形式で出力。SKILL.mdは薄くてよいという好例
4. frontmatterの description にトリガーフレーズを直接列挙（"review my UI", "audit design" 等）
5. 引数がなければユーザーに対象ファイルを尋ねるフォールバックを明記

## 教訓

- 生成（frontend-design）と検証（web-design-guidelines）は別スキルに分離できるが、単一スキル内でも「生成→ガイドライン照合」の2段構えとして取り込める
- チェックリストは外部SSOTへの参照でもよい。スキル本文へ全ルールを転記しない
