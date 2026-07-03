# ナレッジ管理(複数AI・複数セッション協働のため)

このスキルで作るシステムは、1回のセッションでは完成しない。別のAIセッション
(あるいは別のAIツール)が途中から引き継ぐ前提で、判断と知見をファイルに残す。
**会話の中にしかない情報は、次のセッションには存在しない。**

## 基本ルールは project-knowledge スキルに従う

`knowledge/` のディレクトリ構成・ファイル命名・書き込みルーティング・mistakes.md の
記録条件・archive/ の運用は **project-knowledge スキルが正**。利用可能ならそちらに従い、
このファイルは fullstack-dev 固有の運用だけを定める。

project-knowledge が使えない環境(スキルを単体でコピーした場合)向けの最小構成:

```
knowledge/
├── decisions/      # 判断・選択・方針・制約 — YYYY-MM-DD-topic.md
├── research/       # 技術調査・バグ解決 — topic-subtopic.md、「症状 → 原因 → 解決」の順
├── daily/          # 作業ログ・引き継ぎメモ — YYYY-MM-DD.md
├── references/     # 一次資料・URL集
├── archive/        # 廃止ファイルの退避先(削除せず移動し、冒頭に > ARCHIVED: 理由)
└── mistakes.md     # AIの実害あるミスを1ファイルに追記式で記録
```

## 判断の記録先(pdr-manager との境界)

- プロジェクトに `docs/pdr/` が**ある**場合: アーキテクチャ・スタック選定・インフラ構成などの
  重要な意思決定は pdr-manager スキルで `docs/pdr/` に記録し、`knowledge/decisions/` には
  日々の軽い判断のみを書く
- `docs/pdr/` が**ない**場合: すべて `knowledge/decisions/` に書く(勝手に `docs/pdr/` を作らない)

以降、このスキルで「Decision Record に記録する」とあれば、この境界ルールで記録先を決める。
書式は記録先スキルのテンプレートに従う(どちらもなければ「決定 / 理由 / 影響・制約」の3見出し)。

## docs/ と knowledge/ の使い分け

`docs/`(schema.md 等)は「システムの現在の姿」で上書き更新し、`knowledge/` は
「そこに至った経緯と学び」で追記していく — この使い分けが重要。

## 何をいつ書くか(fullstack-dev での運用)

- **Decision Record**: スタック・デプロイ先の選定理由(必須)、設計合意、実装中の方針変更。
  「迷って選んだ」ものは全部書く。迷わなかったものは書かなくてよい
- **research/**: 30分以上ハマった問題、非自明な調査結果。同じ穴に別のAIが落ちるのを防ぐ
- **mistakes.md**: ①実際に間違ったコード・設計・操作を行った ②人間の指摘または後の検証で
  発覚した ③再発しうる一般性がある — 3つすべて満たすときだけ追記

## セッションの始め方・終え方(fullstack-dev 固有)

**引き継ぐ側(セッション開始時)**: `knowledge/mistakes.md` → Decision Record
(`knowledge/decisions/` の status: accepted、`docs/pdr/latest/` があればそれも)→ `docs/` の
順に読む。全部読んでも数分。読まずに書き始めると過去の判断を無自覚に覆す。

**引き渡す側(セッション終了時)**: 未記録の判断を Decision Record に書き、
`knowledge/daily/YYYY-MM-DD.md` に「どこまでやった・次に何をする・今の懸念」を3行残す。
複数セッション協働が前提のため、このスキルでは毎セッション必須
(project-knowledge の「長いセッションの日のみ」より厳しく運用する)。
