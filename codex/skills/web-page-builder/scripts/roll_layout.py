#!/usr/bin/env python3
"""レイアウト抽選(収束防止)。

使い方:
    python roll_layout.py --count 3 [--exclude S02,H02,C05] [--seed 42]

references/layout-skeletons.md を母集団として、案の数だけ
「ページ骨格+ヒーロー型+制約カード」の組を無作為に選ぶ。
出目は起点であって命令ではないが、振り直しは理由を明記して1回まで。
"""
import argparse
import pathlib
import random
import re
import sys

MD = pathlib.Path(__file__).resolve().parent.parent / "references" / "layout-skeletons.md"


def load_pool():
    text = MD.read_text(encoding="utf-8")
    items = re.findall(r"- \*\*([SHC]\d{2})\s+([^*]+?)\*\*", text)
    pool = {"S": [], "H": [], "C": []}
    for code, name in items:
        pool[code[0]].append((code, name.strip()))
    return pool


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=3, help="案の数(1〜4)")
    ap.add_argument("--exclude", default="", help="除外コード(会話内で使用済みのもの) 例: S02,H02")
    ap.add_argument("--seed", type=int, default=None, help="再現用シード(通常は指定しない)")
    a = ap.parse_args()

    rng = random.Random(a.seed)
    pool = load_pool()
    excl = {x.strip().upper() for x in a.exclude.split(",") if x.strip()}
    S = [x for x in pool["S"] if x[0] not in excl]
    H = [x for x in pool["H"] if x[0] not in excl]
    C = [x for x in pool["C"] if x[0] not in excl]

    n = max(1, min(a.count, 4))
    if len(S) < n or len(H) < n or not C:
        print("母集団が不足しています(excludeを減らすかカタログを増やす)", file=sys.stderr)
        return 1

    skeletons = rng.sample(S, n)
    heroes = rng.sample(H, n)
    constraints = rng.sample(C, n) if len(C) >= n else [rng.choice(C) for _ in range(n)]
    print("=== レイアウト抽選結果(起点。題材に合わせて変形する) ===")
    for i in range(n):
        print(f"案{i + 1}: 骨格 {skeletons[i][0]} {skeletons[i][1]}"
              f" / ヒーロー {heroes[i][0]} {heroes[i][1]}"
              f" / 制約 {constraints[i][0]} {constraints[i][1]}")
    print("※致命的に不適合な出目のみ、理由を1行書いて1回だけ振り直し可。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
