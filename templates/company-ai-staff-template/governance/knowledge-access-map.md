# ナレッジアクセスマップ

「どのロールがどのナレッジフォルダに触れてよいか」を一望できる表です。
**この表は手で編集しないでください**。各ロールの `ROLE.md` frontmatter
(`knowledge_sources`)を唯一の正として、`./scripts/generate-registry.sh` が再生成します。

<!-- BEGIN:GENERATED -->
| ナレッジフォルダ \ ロール | ceo-advisor | hr-faq | strategy-advisor | training-trainer |
|---|---|---|---|---|
| company-profile | ○ | - | ○ | - |
| management-policy | ○ | - | ○ | - |
| manuals | - | ○ | - | ○ |
| rules | - | ○ | - | - |
| strategy-data | ○ | - | ○ | - |
| training-materials | - | ○ | - | ○ |
<!-- END:GENERATED -->

## この表の効力について(重要)

この表はAIへの指示+運用ルールであり、それ自体に強制力はありません。
実効性を持たせるのは実行サーフェス側の分離です:
**Projects なら「1ロール = 1 Project、アップロードは knowledge_sources のフォルダのみ」**
(詳細: `knowledge/README.md` の「実行サーフェスごとの分離ルール」)。

## 設計思想

- **横のつながりを最小限にする**: hr-faq や training-trainer のような informational型
  ロールに strategy-data(財務・競合情報)を持たせない。業務上不要な機密情報への
  接触経路をそもそも作らないことが、情報漏洩リスクを下げる一番簡単な方法です
- **advisory型は複数フォルダを横断してよい**: 経営判断には複数領域の情報統合が必要な
  ことが多いため、ceo-advisor と strategy-advisor は広めのアクセス範囲を持たせています。
  その分、`governance/escalation.md` の基準(承認の記録を含む)を厳格に適用してください

## 新しいロールを追加する時のチェック

1. このロールは本当にそのナレッジフォルダを読む必要があるか?(最小権限の原則)
2. informational型なのに strategy-data のような機密フォルダにアクセスしようとしていないか?
3. アクセス範囲が広いロール(advisory型)に `escalation_required: true` を設定したか?
4. 実行サーフェス側でも分離を再現したか?(Project に余計なフォルダを上げていないか)
