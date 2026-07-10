#!/usr/bin/env python3
"""モックアップHTMLの機械チェック(手順7の前段)。

使い方:
    python lint_mockup.py mockups/renewal-*.html

機械判定できる項目だけを検査する(美的判断は担わない):
  - viewport meta / <html lang> / h1がちょうど1つ
  - :root のCSS変数(設計トークン)宣言
  - 冒頭の「案の憲法」コメント(案名・トークン・禁止事項の手すり)
  - :root外のハードコード色(トークンを無視したhex直書き=実装ドリフト)
  - リンクが全てページ内アンカー(無自覚なLP化のサイン)
  - photo-frame の寸法指定(aspect-ratio / height)漏れ
  - 外部画像の直リンクがあるのに読み込み失敗の検知バナーが無い
  - 100vh の使用(100dvh / svh を推奨)

NGが1つでもあると意図的に exit 1 を返す(静かに通さないため)。
簡易検査なので通過は品質の保証ではない——目視と
スクリーンショット検証の前段として使う。
"""
import re
import sys
from html.parser import HTMLParser
from pathlib import Path


class Scan(HTMLParser):
    def __init__(self):
        super().__init__()
        self.viewport = False
        self.lang = False
        self.h1 = 0
        self.hrefs = []
        self.ext_imgs = 0
        self.frames = 0
        self.frames_sized_inline = 0
        self.inline_styles = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if a.get("style"):
            self.inline_styles.append(a["style"])
        if tag == "html" and (a.get("lang") or "").strip():
            self.lang = True
        elif tag == "meta" and a.get("name") == "viewport":
            self.viewport = True
        elif tag == "h1":
            self.h1 += 1
        elif tag == "a" and a.get("href"):
            self.hrefs.append(a["href"])
        elif tag == "img" and (a.get("src") or "").startswith("http"):
            self.ext_imgs += 1
        if "photo-frame" in (a.get("class") or ""):
            self.frames += 1
            if re.search(r"aspect-ratio|height\s*:", a.get("style") or ""):
                self.frames_sized_inline += 1


def hardcoded_hex(text: str, inline_styles: list[str]) -> int:
    """:root外のhex直書きを数える(トークン経由=var()参照を強制するため)。"""
    blocks = re.findall(r"<style[^>]*>(.*?)</style>", text, re.S | re.I)
    css = "\n".join(blocks)
    css = re.sub(r"/\*.*?\*/", "", css, flags=re.S)  # CSSコメント内は除外
    css = re.sub(r":root\s*\{[^}]*\}", "", css)  # :root(トークン定義)は除外
    n = len(re.findall(r"#[0-9a-fA-F]{3,8}\b", css))
    n += sum(len(re.findall(r"#[0-9a-fA-F]{3,8}\b", st)) for st in inline_styles)
    return n


def lint(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    s = Scan()
    s.feed(text)
    ng = []
    if "案の憲法" not in text[:3000]:
        ng.append("冒頭に「案の憲法」コメントが無い(案名・トークン・禁止事項を10行以内で。SKILL.md手順6)")
    hexes = hardcoded_hex(text, s.inline_styles)
    if hexes:
        ng.append(f"トークン外のハードコード色が{hexes}箇所(:rootで変数化してvar()参照に)")
    if not s.viewport:
        ng.append("viewport metaが無い(モバイルで縮小表示される)")
    if not s.lang:
        ng.append('<html lang="ja"> のlang属性が無い')
    if s.h1 != 1:
        ng.append(f"h1が{s.h1}個(1ページに1つ)")
    if not re.search(r":root\s*\{[^}]*--", text):
        ng.append(":root のCSS変数(設計トークン)宣言が無い")
    if s.hrefs and all(h.startswith("#") for h in s.hrefs):
        ng.append("リンクが全てページ内アンカー——無自覚なLP化のサイン(下層への導線・サイトマップを)")
    if s.frames:
        css_sized = re.search(r"\.photo-frame\s*[,{][^}]*(aspect-ratio|height\s*:)", text)
        if s.frames_sized_inline < s.frames and not css_sized:
            n = s.frames - s.frames_sized_inline
            ng.append(f"photo-frame {n}/{s.frames}箇所に寸法(aspect-ratio/height)が無い——高さ0に潰れる")
    if s.ext_imgs and "naturalWidth" not in text:
        ng.append(f"外部画像の直リンクが{s.ext_imgs}枚あるのに、読み込み失敗の検知バナーが無い")
    if re.search(r"\b100vh\b", text):
        ng.append("100vhを使用している(モバイルでアドレスバー分ずれる——100dvh/svhに)")
    return ng


def main(paths: list[str]) -> int:
    if not paths:
        print(__doc__)
        return 1
    failed = False
    for p in paths:
        path = Path(p)
        if not path.is_file():
            print(f"== {p}\n  NG ファイルが見つからない")
            failed = True
            continue
        ng = lint(path)
        if ng:
            failed = True
            print(f"== {p}")
            for m in ng:
                print(f"  NG {m}")
        else:
            print(f"== {p}\n  OK")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
