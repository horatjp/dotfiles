# company-ai-staff-template

会社の業務をAI(ロール/Skill)で運用するための、汎用的なテンプレート一式です。
「AI社員(人格)」として作るか、「Skill(業務手順)」として作るかはこだわりません。
`roles/` 配下のファイルはどちらの形でも機能する共通フォーマットになっています。

## まずはここから:最小構成で始める

一式揃っていますが、**最初から全部使う必要はありません**。

| 段階 | 使うもの | 導入の目安 |
|---|---|---|
| 1(必須) | `roles/` + `knowledge/` + `governance/escalation.md` | 最初から |
| 2 | 台帳・アクセスマップ(`scripts/generate-registry.sh` で自動生成) | ロールが増えて把握しづらくなったら |
| 3 | 連携(疑似会議 / GitHub Issues)、API/Agent化 | 複数ロールの突き合わせ・自動化が実際に必要になったら |

## 設計思想:4層構造

```
┌─────────────────────────────────────────┐
│ 4. ガバナンス層(governance/)              │
│    エスカレーション基準・承認ログ・台帳       │
├─────────────────────────────────────────┤
│ 3. 実行サーフェス層(governance/execution-guide.md) │
│    Projects / Cowork / Claude Code / API   │
├─────────────────────────────────────────┤
│ 2. 連携層(governance/coordination.md)     │
│    疑似会議 / 別セッション独立実行 / GitHub連携 │
├─────────────────────────────────────────┤
│ 1. 機能単位層(roles/ + knowledge/)        │
│    ロール定義(業務手順・人格どちらでも)+ 参照資料 │
└─────────────────────────────────────────┘
```

全ロールに共通する骨格は以下の3点です:

- **役割(誰の代理か)とナレッジ(何を参照するか)を分離する**
- **参照範囲を限定し、ファイル外の情報は「情報なし」と正直に言う**
- **決まった出力フォーマットとフォローアップ質問で終える**

これを1層目として、その上に「どこで実行するか(3層目)」「複数ロールをどう組み合わせるか
(2層目)」「暴走させないための歯止め(4層目)」を積み重ねる構成にしています。

```
company-ai-staff-template/
├── knowledge/                     ← 会社の実データを入れる場所
│   ├── README.md                  ← 格納ルール・機密度の考え方(最初に読む)
│   ├── company-profile/           ← ミッション・ビジョン・事業内容
│   ├── management-policy/         ← 経営方針
│   ├── manuals/                   ← 業務マニュアル
│   ├── rules/                     ← 就業規則
│   ├── training-materials/        ← 研修資料
│   ├── strategy-data/             ← 業界レポート・競合分析(機密度高)
│   └── archive/                   ← 旧版資料の置き場(どのロールも参照しない)
│
├── roles/                         ← AIロールの定義
│   ├── _template/
│   │   ├── ROLE_TEMPLATE.md       ← 新規ロール作成用の雛形
│   │   └── learnings_template.md
│   ├── ceo-advisor/               ← 経営アドバイザー(意思決定の壁打ち)
│   ├── strategy-advisor/          ← 戦略参謀(分析・資料化)
│   ├── hr-faq/                    ← 社内FAQデスク
│   └── training-trainer/          ← 新人育成トレーナー
│       └── (各ロールに ROLE.md + learnings.md)
│
├── skills/                        ← 連携用の共通Skill
│   └── meeting-simulation/        ← 複数ロールの視点を1セッションで議論させる
│
├── governance/                    ← 全社共通のルール
│   ├── role-registry.md           ← ロール台帳(スクリプトで自動生成)
│   ├── knowledge-access-map.md    ← ナレッジアクセスマップ(同上)
│   ├── escalation.md              ← 人間の承認が必要な場面の基準
│   ├── approvals.md               ← 承認ログ(実行前に1行追記)
│   ├── execution-guide.md         ← どのサーフェスで動かすかの判断フロー
│   └── coordination.md            ← 複数ロールをどう協働させるか(3レベル)
│
└── scripts/
    ├── new-role.sh                ← 新規ロールの雛形を作成
    ├── generate-registry.sh       ← frontmatterから台帳・マップを再生成
    ├── check-blocked.sh           ← GitHub Issues連携用(依存解決の自動チェック)
    └── prune-learnings.md         ← learnings.mdの月次棚卸し手順
```

## 使い方

### 0. 大前提を理解する

`knowledge/README.md` の「防げること・防げないこと」を最初に読んでください。
この仕組みの参照制限はAIへの指示+運用ルールであり、悪意ある利用者やプロンプト
インジェクションまでは防げません。それらを防ぐのは実行サーフェス側の権限設計です。

### 1. 自社のナレッジを入れる

`knowledge/` 配下の各フォルダに、実際の会社資料を入れます。まずは機密度の低いもの
(company-profile, manuals, training-materials)から始めるのがおすすめです。

### 2. 4つの基本ロールを自社向けに調整する

`roles/*/ROLE.md` 内の `{{会社名}}` を実際の社名に置き換え、対象業務や確認項目を
自社の実態に合わせて書き換えます。テンプレートのままでは一般的すぎるので、
最初の1〜2週間は実際のやり取りを見ながら育てていく前提で使ってください。

**命名の注意**: 「社長クローン」のような「実在役職+クローン」の命名は避けることを
推奨します。AIの提案が本人の見解として一人歩きしやすくなるため、このテンプレートでは
機能名(経営アドバイザー等)を標準にしています。

### 3. type と allow_general_knowledge を設定する

ロールの性質は2つの独立した軸で決めます(定義と判定基準は `governance/role-registry.md`):

- **type**: `informational`(情報提供のみ)/ `advisory`(提案・分析。
  `escalation_required: true` 必須)
- **allow_general_knowledge**: 一般知識での補完を許すか(typeとは独立。
  例: training-trainer は informational だが教え方の補完に一般知識が必要なので true)

ここを曖昧にすると、AIの提案がいつの間にか経営判断そのものとして扱われるリスクがあります。

### 4. 実行サーフェスに配置する

「単発の質問」なら Claude Projects、「複数ステップの作業」なら Cowork、「自動化・
ファイル操作」なら Claude Code、「定期実行」なら API/Agent化。判断フローは
`governance/execution-guide.md` にあります。迷ったら軽い方(Projects)から。

**最重要ルール**: Projects で使う場合は **1ロール = 1 Project** とし、そのロールの
`knowledge_sources` にあるフォルダの中身だけをアップロードしてください。
`knowledge/` を丸ごと上げた時点で、アクセス制限は機能しなくなります。

### 5. 必要に応じてロールを追加する

```bash
./scripts/new-role.sh sales-advisor "営業戦略アドバイザー"
# frontmatterと本文を埋めたら:
./scripts/generate-registry.sh
```

台帳(`role-registry.md`)とアクセスマップ(`knowledge-access-map.md`)は
frontmatter から自動生成されるため、手で編集しません。
追加する前に「既存ロールの調整で表現できないか」を必ず確認してください。
ロールの増殖が「誰に何を頼めばいいか分からない」状態の最大の原因です。

### 6. 複数ロールの視点を組み合わせたい時

まずは `skills/meeting-simulation/SKILL.md`(疑似会議)を試し、独立した見立てが
欲しければ別セッションでの個別実行、本当に非同期の並行作業が必要になった場合のみ
GitHub Issues 連携に格上げします。3レベルの使い分けは `governance/coordination.md` へ。

### 7. 運用しながら育てる

- **learnings.md**: Claude Code 経由なら自動追記できます。Projects 経由の場合は
  セッション終わりの付随質問(Q3)で気づきを拾い、週次/月次で転記してください
- **月次**: `scripts/prune-learnings.md` の手順で learnings を棚卸し(PR経由)
- **四半期**: `governance/role-registry.md` の基準で不使用ロールを整理
  (frontmatter の `last_used` を更新してから `generate-registry.sh` を実行)
- **advisory の提案を実行に移す時**: 必ず `governance/approvals.md` に承認を記録

## Claude Code / GitHub との接続(補足)

- ロール定義は Claude Code 等の **Skill** としてそのまま登録できます
  (`roles/*/ROLE.md` を `.claude/skills/<role_id>/SKILL.md` として配置する形でも動きます)
- 各ロールへの依頼・完了報告は **GitHub Issues 運用**に乗せられます
  (`governance/coordination.md` のレベル2、`scripts/check-blocked.sh` 同梱)
- 業務データには機密情報が混ざりやすいため、リポジトリはプライベート必須です。
  詳細は `knowledge/README.md` の「このリポジトリ自体の置き場所」を参照してください
