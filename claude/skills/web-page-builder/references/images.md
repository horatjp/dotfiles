# 画像の扱い（images）

Step 3（実装）で画像を扱うときの規律。品質が提案の足を引っ張ることを防ぐ。

## 大原則: Claudeは自分で画像を「描かない」

SVG/CSSによるイラスト、疑似的な商品・店舗ビジュアル、装飾アイコンの自作は**禁止**。品質がサイト全体を毀損する。絵文字をアイコン代わりにするのも論外（🚀✨💡の類）。

使ってよいレイアウト表現: 背景色・色面・罫線・余白・タイポグラフィ（大きな数字や文字のあしらい）。アイコンが必要なら Phosphor / Tabler 等の既製アイコンセット。

## 素材の優先順位

1. **実素材**（ユーザー提供の写真・ロゴ）: 最優先。入手できたらPILで圧縮（長辺1200〜1600px・JPEG品質75前後）してbase64埋め込み（どの表示環境でも確実に表示される）
2. **生成画像**（画像生成ツールが環境にある場合のみ）: Claudeは仕様書（被写体・構図・光+ページのトーン）を書き、生成は相手に任せる。同一ページ内はトーン指定を共通化。画像内に文字（特に日本語）を入れない。生成イメージである旨と差し替え前提を明記
3. **ライセンス明確なフリー素材**（Unsplash等）: 取得できる環境ではダウンロード→base64。できない環境では直リンク（下記の実装形で）。`plus.unsplash.com` や「For Unsplash+」表記の有料素材は除外。URLの `w=` `q=` は `w=1600&q=75` 程度に
4. **写真プレースホルダー（FPO）**: 最後の手段。でっち上げず「指定」する——実装時と同じ比率の色面ブロックに「ここに: 店舗外観/横位置/夕方の光」のように被写体・構図・撮影メモをラベル表示。これがそのまま撮影リストになる

手軽な代替として `https://picsum.photos/seed/{説明}/{w}/{h}` も可（雰囲気確認用。被写体指定が必要な箇所には使わない）。

## 直リンク画像の実装形（必須）

外部URLを直リンクする場合は、フレームに必ず寸法を与え、失敗をサイレントにしない:

```html
<figure class="photo-frame" style="aspect-ratio: 4/3;">
  <span class="fpo-label">ここに: 被写体・構図・光のメモ</span>
  <img src="(fetch結果からコピーしたURL)" alt="◯◯（イメージ写真・差し替え前提）"
       loading="lazy" onerror="this.style.display='none'">
</figure>
```
```css
.photo-frame{position:relative; overflow:hidden; background:#eee}
.photo-frame .fpo-label{position:absolute; inset:0; display:flex; align-items:center;
  justify-content:center; text-align:center; font-size:11px; padding:12px}
.photo-frame img{position:absolute; inset:0; width:100%; height:100%; object-fit:cover}
```

- **フレーム側に `aspect-ratio` または `height` を必ず与える**（中身が全て absolute のため無指定だと高さ0に潰れる）
- ページ末尾に読み込み失敗の検知バナーを入れる（外部画像がブロックされる表示環境で「壊れて見える」事故を防ぐ）:

```html
<script>
addEventListener('load',()=>{setTimeout(()=>{const b=[...document.images].filter(i=>i.src.startsWith('http')&&(!i.complete||i.naturalWidth===0));if(b.length){const d=document.createElement('div');d.textContent='※ 外部画像 '+b.length+' 枚がこの表示環境で読み込めていません。ファイルをダウンロードしてブラウザで開くと表示されます。';d.style.cssText='position:fixed;left:12px;right:12px;bottom:calc(12px + env(safe-area-inset-bottom));z-index:999;background:#1f2328;color:#fff;padding:10px 16px;border-radius:8px;font-size:12.5px;opacity:.95;text-align:center';document.body.appendChild(d)}},600)});
</script>
```

- 直リンクの `src` は必ずこの会話の `web_fetch` 結果からコピーする（記憶からphoto IDを書くと、もっともらしい形でも404になる）

## Unsplash調達の手順（検証済み）

1. `web_search` で「unsplash <被写体の英語キーワード>」を検索（日本語より英語が高精度）、`unsplash.com/s/photos/...` ページを `web_fetch`
2. 結果に含まれる `images.unsplash.com/photo-...` 形式のURL・alt文・撮影者名から、**alt文を読んで被写体が合うものを選ぶ**
3. 先に必要な枚数と用途（ヒーロー用・商品用…）をリスト化してから一括で確保・配分する（1枚ごとに検索し直さない）。トーンを揃えるため、なるべく同じ撮影者・同じシリーズから選ぶ
4. 撮影者名と「イメージ写真・差し替え前提」であることを納品時に明記する

## 品質ルール

- **枚数の目安**: 写真が主役級の業種（飲食・食品・美容・宿・小売など）はトップページで5〜8枚（ヒーロー/主力商品/一覧グリッド/人・店内・仕事風景/店舗案内）。2〜3枚では説得力が出ない。タイポグラフィ主導で意図的に絞る場合はその旨を宣言する
- **トーンを揃える**: 明るさ・彩度・色温度がバラバラのストック写真の寄せ集めは一気に安っぽくなる
- **写真に文字を重ねるならスクリム**（半透明オーバーレイ）必須。コントラストはスクリム適用後の実効背景色で `<スキルのパス>/scripts/check_contrast.py` にかける
- base64はHTMLを1枚あたり50〜150KB太らせる。合計1MBを超えそうなら主要写真だけ埋め込み、残りは直リンク+検知バナーのハイブリッドに
- 実在の店舗・商品・人物を「本物らしく」再現しない。権利不明なドメインの画像は埋め込まない
