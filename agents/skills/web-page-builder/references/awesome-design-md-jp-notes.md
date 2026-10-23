# 取り込みメモ: aradotso/trending-skills @ awesome-design-md-jp

- 出典: https://github.com/aradotso/trending-skills （skills/awesome-design-md-jp/SKILL.md 549行）。元ネタは kzhrknt/awesome-design-md-jp
- 目的: 日本語UI向けの正確な DESIGN.md（AIエージェントが読むデザイン仕様書）を作る。Google Stitch DESIGN.md形式をCJK拡張

## 良い点・転用ポイント

1. **DESIGN.md の9セクション標準構造**: Overview → Color Palette → Typography → Spacing & Layout → Components → Icons & Imagery → Motion → Responsive Breakpoints（トークンは表形式で `--color-primary` 等のCSS変数名+値+用途）
2. **CJKフォントフォールバックチェーン**: 和文（Noto Sans JP → Hiragino → Meiryo → Yu Gothic）と欧文（Inter → system）を分離し、混植は unicode-range で欧文フォントを重ねる
3. **日本語タイポの数値仕様**:
   - 行高: 本文1.7-2.0（欧文の1.4-1.5より広い）
   - letter-spacing: 本文 0.04em-0.1em、見出しは0か僅かに負
   - タイプスケール表（Display 2.5rem/1.4 〜 Caption 0.75rem/1.6）
4. **禁則処理（kinsoku shori）をCSSで指定**: `line-break: strict` + `overflow-wrap: break-word`。行頭禁則（）」』】、。等）・行末禁則（（「『【）の文字リストつき
5. **OpenType機能**: `font-feature-settings: "palt" 1, "kern" 1`（プロポーショナル約物+カーニング）
6. **スペーシング**: 8px基準のトークン（xs4/sm8/md16/lg32/xl64）、最大幅1200px、モバイル左右24px
7. **実在サービス24例のDESIGN.mdを参照集として同梱**（Apple Japan, MUJI, Mercari, SmartHR, freee, note, LINE, Rakuten, Qiita, Zenn, pixiv…）— テンプレをコピーして編集する導線
8. frontmatterに `triggers:` としてトリガーフレーズを配列で列挙するパターン

## 後半の要点（サービスカテゴリ別プリセット等）

- **カテゴリ別デフォルト表**:
  - Consumer App（LINE/メルカリ型）: Noto Sans JP、行高1.7、ls 0.04em、モバイルファースト375px、タップ48px以上
  - B2B SaaS（SmartHR/freee型）: Hiragino優先、行高1.8（データ表は1.5可）、中立パレット+明確なアクション色、高情報密度
  - Editorial/Media（note/Qiita型）: 本文に Noto Serif JP/明朝、行高1.9-2.0、ls 0.06em、1行38-42文字
  - Retail/Lifestyle（MUJI型）: プレミアムはセリフ、行高2.0、ls 0.08em、無彩色系パレット、写真が主役
- 各DESIGN.mdに preview.html（トークン可視化）を同梱する運用
- **トラブルシューティング**: AIが "MS Gothic" や generic sans-serif に簡略化する問題 → フォールバックチェーンに「簡略化禁止」と各段のプラットフォーム注記を書く
- AIへの指示例文（「DESIGN.mdを読み、定義された値を正確に使え。line-break: strict で禁則を実装せよ」）を同梱

## 教訓

- 「サイトを作る前にDESIGN.md（デザイン仕様1枚）を書く」ワークフローは、tsubotaxのハーネス思想（AI向け翻訳メモ）と完全に一致する
- 日本語サイトなら禁則処理・palt・行高・letter-spacing はスキルが暗黙に適用すべきデフォルト
