---
name: multi-agent-kickoff
description: 複数のAIエージェント(監督・実装・レビューなど)を herdr のペインで組んで、プロジェクトや大きめの作業を進めるときに使う。ユーザーが「マルチエージェントで」「複数エージェントで進めて」「CodexとClaudeで分担して」「実装とレビューを別のAIに」「チームを組んで」と言ったとき、または監督役として他のエージェントに実装・レビューを任せるときに必ず使う。1つのセッションで済む小さな作業には使わない。
---

# マルチエージェントの起動と監督

監督(このセッション)は原則として自分では実装しない。作業を分け、役割ごとのエージェントを herdr のペインで起動し、依頼はファイル、声かけ・ペインどうしの会話は `hc send`(TUI の herdr は `herdr agent prompt`)で行う。レビューを通ったものだけを監督がコミットする。決まりは目的と境界だけで、細部はエージェントの自律に任せる。

- 決まりの原本は ai-watch の playbook(下の「原本と更新」)で、[references/playbook.md](references/playbook.md) はその写し(目的・境界・チーム表・連絡と見張り・依頼文に書くこと・記録)。起動の前に読む
- 道具: ペインの操作は `herdr-app` スキル(herdr-app の中)または `herdr` スキル(TUI)。どちらかは `herdr-app` スキルの「どちらを使うか」で決める

## 手順
1. **チームを決める。** playbook §3 の表から役割とモデルを選ぶ。実装した人とレビューする人は別系統(提供元が違う)にする。常に動かすのは3体まで。起動の前に Claude と Codex の残りの枠を見る(playbook §3)。
2. **計画を書いてユーザーに見せ、了承を得てから起動する。** 項目・担当・順番(触るファイルが重ならないように)・完了条件・禁止事項を、プロジェクト内のファイル(例: `reports/<日付>/PLAN.md`)に書く(計画のコミットは、門番を通った変更と一緒にする。門番は playbook §2)。新しいフォルダで Claude を動かすときは、そのフォルダの信頼も一緒に聞く(扱いは playbook §2 の確認画面の項)。
3. **起動する。** ペインを開き(監督のペインは上下に分けない。ほかは右側にまとめる)、依頼文を書いて `hc send` の1行で知らせる。依頼文の中身は playbook §5 とひな形。作業役・レビュー役の依頼文には playbook §2 の「権限の決まり」の文をそのまま入れる。herdr-app のペインの開き方・待ち方は `herdr-app` スキル。TUI の herdr では `herdr pane split --current --direction right --cwd "$PWD" --no-focus`(2体目からは前のペインを `--pane` に指定して `down`。返ってきた `.result.pane.pane_id` を使う) → `herdr pane rename <ペイン> "<役割> (<モデル>)"` → `herdr agent start <名前> --kind <種類> --pane <ペイン>` の順で開く(`agent start` の名前はコマンドで呼ぶためのもので、画面の見出しには出ない。見出しが空だとどのペインが誰か分からない)。
4. **見張る**(playbook §4)。止まり・終わり・見張り自体の失敗に気づけるようにし、止まっているエージェントには声をかける。確認画面の許可は playbook §2。終わりは `scripts/wait-signal.sh`(使い方と終了コードはスクリプトの先頭)かファイルで待つ。報告はまず要点と集計の行だけ読み、本文や画面は門番で根拠を確かめるとき・P1/P2 が残るとき・止まったときに開く。
5. **門番をする**(条件は playbook §2 の門番の項)。2者に見せている間は両方が返るまで差分を直させず、返ったら作業役に知らせる。
6. **有料の実行・元に戻せない操作は playbook §2 の境界のとおり**(承認はユーザー、実行は監督の専用の端末。herdr-app は hc の専用端末で、終わりは `hc wait <t>`・止めるのは `hc kill <t>`)。Pi の費用・枠の見張りは references/pi.md。
7. **報告して片付ける**(playbook §6)。見張りを止め、自分が開いたペインを閉じ、原本の `multi-agent-runs.md` に振り返りの1行を足す(書き込みを許された範囲のときだけ)。

## 依頼文のひな形
- [references/templates/request-impl.md](references/templates/request-impl.md) — 作業役への依頼
- [references/templates/request-review.md](references/templates/request-review.md) — レビュー役への依頼

## 予備環境(Pi)
Claude と Codex が使えないとき、またはそれ以外のモデルを入れたいとき。費用の上限と見張り(OpenRouter は費用の自動の見張り、Go は枠の残りを監督が見る)・提供元の固定・承認は境界なので、[references/pi.md](references/pi.md) を確かめてから。

## 原本と更新
原本は `<ai-watch>/docs/knowledge/multi-agent-playbook.md`(`<ai-watch>` は ai-watch リポジトリを置いた場所。マシンごとに違う)と同 `multi-agent-pi.md`。`references/` はその写し(同じ内容)。日付つきの経過・測定・旧版は同 `multi-agent-trials.md`。ai-watch で原本を直すきっかけは、新しいモデルを測り終えたとき・週1回の全体監査のとき・同じ詰まりが2回起きたとき。ここへの写し直しは常設の了承(2026-10-09、10-23 に確認)で行い、直した内容をユーザーに1〜2行で報告する。
