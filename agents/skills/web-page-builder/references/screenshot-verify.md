# スクリーンショット検証（screenshot-verify）

Step 4で**必ず試みる**。コードレビューだけでは重なり・折り返し破綻・実際のコントラスト・余白バランスは掴めない。PC幅とモバイル幅の両方を撮る。

## 手段1: Playwright ヘッドレスChromium（サンドボックス内で完結）

Linux環境（サンドボックス/CI）向けの手順。macOSでは通常 `npx playwright install chromium` だけで動き、`ldd`やライブラリスタブは不要（`ldd`はLinux専用コマンドで、macOSには存在しない）。

```bash
# 1) インストール（--with-depsのsudo失敗は無視してよい。本体DLが済めばOK）
npx playwright install chromium

# 2) 不足ライブラリの確認
ldd ~/.cache/ms-playwright/chromium_headless_shell-*/chrome-linux/headless_shell | grep 'not found'
```

不足が `libXdamage.so.1` 等少数のX11系なら、スタブで満たせる（ヘッドレスでは実際には呼ばれない）:

```bash
mkdir -p /tmp/stublibs && cat > /tmp/xd.c <<'EOF'
int XDamageQueryExtension(void*a,int*b,int*c){return 0;}
int XDamageQueryVersion(void*a,int*b,int*c){return 0;}
unsigned long XDamageCreate(void*a,unsigned long b,int c){return 0;}
void XDamageDestroy(void*a,unsigned long b){}
void XDamageSubtract(void*a,unsigned long b,unsigned long c,unsigned long d){}
void XDamageAdd(void*a,unsigned long b,unsigned long c){}
EOF
gcc -shared -fPIC -o /tmp/stublibs/libXdamage.so.1 /tmp/xd.c -Wl,-soname,libXdamage.so.1
```

撮影（PC 1440px と モバイル 375px の2枚、full-page）:

```bash
LD_LIBRARY_PATH=/tmp/stublibs npx playwright screenshot --full-page \
  --viewport-size=1440,900 "file:///<HTMLの絶対パス>" shot-desktop.png
LD_LIBRARY_PATH=/tmp/stublibs npx playwright screenshot --full-page \
  --viewport-size=375,812  "file:///<HTMLの絶対パス>" shot-mobile.png
```

縦長PNGは分割してから見る（読み込み時の縮小で細部が潰れるため）:

```python
from PIL import Image
im = Image.open('shot-mobile.png'); h = im.size[1]
im.crop((0, 0, im.size[0], h//2)).save('shot-mobile-1.png')
im.crop((0, h//2, im.size[0], h)).save('shot-mobile-2.png')
```

## Webフォントの罠（重要）

サンドボックスは `fonts.googleapis.com` への通信をブロックすることがあり、その場合**スクリーンショットはフォールバック書体で描画される**（レイアウト検証はできるが、書体の検証にはなっていない）。書体が判断に関わる検証（参照画像との書体照合・タイポ主導のデザイン）では、フォント実体を埋め込んでから撮る:

```bash
# github.com/google/fonts からTTFを取得（gitは通ることが多い）
git clone -q --depth 1 --filter=blob:none --sparse https://github.com/google/fonts /tmp/gfonts
cd /tmp/gfonts && git sparse-checkout set ofl/notosansjp ofl/oswald  # 必要なファミリーのみ
```

```python
# 検証用の一時コピーに @font-face（base64）を注入して撮影する（納品ファイルはCDNリンクのままでよい）
import base64, pathlib
src = pathlib.Path('<HTML>').read_text()
b = base64.b64encode(pathlib.Path('/tmp/gfonts/ofl/notosansjp/NotoSansJP[wght].ttf').read_bytes()).decode()
face = f'<style>@font-face{{font-family:"Noto Sans JP";src:url(data:font/ttf;base64,{b});font-weight:100 900;}}</style>'
pathlib.Path('/tmp/verify.html').write_text(src.replace('<style>', face+'\n<style>', 1))
```

書体同定（SKILL.md「参照画像からの作成」）の候補比較HTMLも、必ずこの方法で実フォントを当ててから参照画像と突き合わせること。

## 手段2: フォールバック

1. claude-in-chrome 等のブラウザ操作ツールがあれば、`file://` でHTMLを開いてスクリーンショット
2. どちらも無い環境では、コードレビュー+`check_contrast.py` で代替し、「実表示は未確認」とユーザーに明示する

## 確認観点（撮ったら必ず見る）

- **要素の重なり**: 絶対配置・負マージンの要素がテキストを覆っていないか（最頻のバグ。グリッドで領域を確保してから見切らせる）
- **折り返し破綻**: 巨大見出し・nowrap行が列幅を超えていないか。`<br>` 固定改行が狭幅で不自然になっていないか（モバイルでは `br{display:none}` で自然折返しに逃がす手がある）
- **はみ出し・横スクロール**: モバイル幅で全セクションを下までスクロールして確認
- **フォント読込**: Webフォントが実際に当たっているか（フォールバック表示になっていないか）
- **画像**: FPOラベルが読めるか、直リンク画像の枠が潰れていないか（高さ0）
- 直したら**もう一度撮って**見る。1回の修正で直った前提にしない
