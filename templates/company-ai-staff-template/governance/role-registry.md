# AIロール台帳(role-registry)

全AIロールの一覧です。「誰に何を頼めばいいか分からない」状態を防ぐための台帳ですが、
**下の表は手で編集しないでください**。各ロールの `ROLE.md` frontmatter を唯一の正として、
`./scripts/generate-registry.sh` が再生成します(「状態」「最終利用日」も frontmatter の
`status` / `last_used` を更新してから再生成する)。

<!-- BEGIN:GENERATED -->
| role_id | title | 部門 | type | 一般知識補完 | 参照ナレッジ | エスカレーション必須 | 配置サーフェス | 状態 | 最終利用日 |
|---|---|---|---|---|---|---|---|---|---|
| ceo-advisor | 経営アドバイザー(経営相談役) | 経営 | advisory | ○ | company-profile, management-policy, strategy-data | ✅ | projects | active | - |
| hr-faq | 社内FAQデスク(コーポレート問合せ対応) | 総務・人事・経理 | informational | - | manuals, rules, training-materials | - | projects | active | - |
| strategy-advisor | 戦略参謀(経営企画支援) | 経営企画 | advisory | ○ | strategy-data, company-profile, management-policy | ✅ | projects | active | - |
| training-trainer | 新人育成トレーナー | 教育研修 | informational | ○ | training-materials, manuals | - | projects | active | - |
<!-- END:GENERATED -->

## type と allow_general_knowledge の定義

ロールの性質は**2つの独立した軸**で決めます(1つの軸に押し込めると、
「資料の範囲内で教材を作るが判断はしない」のようなロールで破綻します):

- **type(判断・提案をするか)**
  - `informational`: 決まった資料の中から答える。判断・提案はしない
  - `advisory`: 提案・分析を行う。出力が意思決定に使われうるため
    `escalation_required: true` を必須とする
- **allow_general_knowledge(一般知識で補完するか)**
  - `false`: 資料にないことは固定の不明時文言のみを返す(例: hr-faq)
  - `true`: 一般知識で補完可。ただし事実と補完を区別し、社内固有の情報は補完しない
    (例: training-trainer は informational だが、教え方・出題形式に一般的な
    教育理論が必要なので true)

**判定に迷ったら**: 「この出力を根拠に、誰かが行動を変える(お金・人・対外発信が動く)か?」
→ YES なら advisory。迷い続けるなら advisory に倒す(安全側)。

## ロールの使い分けメモ

参照ナレッジが重なるロールは、**入力の種類ではなく出力の性質**で使い分けを定義します:

- **ceo-advisor**: 意思決定の壁打ち。選択肢を**絞り**、推奨案を出す
- **strategy-advisor**: 分析・資料化。選択肢を**広げ**、判断材料を整理する

使い分けが書けないロールペアは、統合を検討してください。

## 新しいロールを追加する手順

1. `./scripts/new-role.sh <role_id> "<タイトル>"` で雛形を作成
2. `ROLE.md` の frontmatter(type / allow_general_knowledge / knowledge_sources 等)と本文を埋める
3. `knowledge/` 配下に必要なフォルダがなければ追加し、`knowledge/README.md` の表を更新
4. `./scripts/generate-registry.sh` を実行して台帳とアクセスマップを再生成
5. type が advisory の場合、`governance/escalation.md` の基準を満たしているか確認

**追加する前に**: 既存ロールの knowledge_sources や type の調整で表現できないかを
先に確認してください。ロールの増殖こそが「台帳が整理候補だらけになる」原因です。

## 定期棚卸しの基準

四半期に一度、以下を確認してください:

- `last_used` が3ヶ月以上前(または空)のロール → 統合または廃止を検討
  (廃止する場合は frontmatter を `status: retired` にして再生成。削除の最終判断は人間が行う)
- 似た役割のロールが重複していないか → 統合を検討
- `knowledge_sources` が古いまま更新されていないロールはないか

**最終利用日(`last_used`)の更新方法** — 計測手段のない棚卸し基準は機能しません:

- Claude Code 経由の利用: `learnings.md` への追記日で代替できる
- Projects 経由の利用: 月次で各ロールのオーナーが frontmatter の `last_used` を
  自己申告で更新する(粗くてよい。「一度も更新されない」こと自体が不使用のシグナル)

## skills/ について

`skills/` 配下(meeting-simulation 等)はロールではなく連携用の仕組みのため、
この台帳の対象外です(`governance/coordination.md` 参照)。
