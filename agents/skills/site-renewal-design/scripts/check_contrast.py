#!/usr/bin/env python3
"""文字色×背景色のWCAGコントラスト比チェック。

使い方:
    python check_contrast.py "#333333,#f7f5f0" "#ffffff,#1a1a1a" ...

各引数は「前景色,背景色」のHEXペア。結果として比率と、
本文(AA: 4.5以上) / 大きな文字・UI部品(AA: 3.0以上)の合否を表示する。
目視の印象より、この数値を優先すること。
本文AAのNGが1つでもあると意図的に exit 1 を返す(静かに通さないため)。
"""
import sys


def _channel(c: float) -> float:
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(hex_color: str) -> float:
    h = hex_color.strip().lstrip("#")
    if len(h) == 3:
        h = "".join(ch * 2 for ch in h)
    if len(h) != 6:
        raise ValueError(f"HEX色として解釈できません: {hex_color}")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b)


def ratio(fg: str, bg: str) -> float:
    l1, l2 = sorted((luminance(fg), luminance(bg)), reverse=True)
    return (l1 + 0.05) / (l2 + 0.05)


def main(pairs: list[str]) -> int:
    if not pairs:
        print(__doc__)
        return 1
    worst_fail = False
    for pair in pairs:
        try:
            fg, bg = (p.strip() for p in pair.split(","))
            r = ratio(fg, bg)
        except Exception as e:
            print(f"NG   {pair}: {e}")
            worst_fail = True
            continue
        body = "OK" if r >= 4.5 else "NG"
        large = "OK" if r >= 3.0 else "NG"
        if body == "NG":
            worst_fail = True
        print(f"{r:5.2f}:1  本文AA[{body}] 大文字/UI AA[{large}]  {fg} on {bg}")
    print("\n本文AAがNGの組み合わせは、本文には使わない(大見出し・装飾に限定するか色を調整)。")
    return 1 if worst_fail else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
