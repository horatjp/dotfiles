#!/usr/bin/env python3
"""m4a → MP3 変換パイプライン (MusicBee + MP3Gain + タグ削除の再現)

各ファイルに対して:
1. ffmpeg の replaygain フィルタで音量解析 (ReplayGain, 基準89dB)
2. LAME (libmp3lame) で 320kbps CBR に変換。
   目標音量 (デフォルト96dB) になるようゲインをエンコード時に適用
   → MP3Gain と同じ基準の音量調整。再エンコード前に適用するので劣化なし
3. タグ整理: アルバム名(TALB)・全ソートタグ(読みがな)・iTunes系TXXXを削除。
   曲名/アーティスト/ジャンル/トラック番号/年/アートワークは保持
4. 出力ファイル名は「アーティスト名 - タイトル.mp3」(タグから生成)
5. 歌詞埋め込み: txtディレクトリに歌詞ファイル(.txt/.lrc)が存在する場合のみUSLTタグとして埋め込む。
   変換済みファイルに対しても、後から歌詞を置いて再実行すれば埋め込まれる(再エンコードなし)

必要環境: ffmpeg (libmp3lame有効), Python3, mutagen
使い方:
  python3 convert.py <入力dir|ファイル...> -o <出力dir> [--target-db 96] [--no-clip]
"""
import argparse
import math
import re
import subprocess
import sys
from pathlib import Path

from mutagen.id3 import ID3, USLT
from mutagen.mp3 import MP3

REFERENCE_DB = 89.0  # ReplayGain / MP3Gain の基準音量

# 削除するID3フレーム: アルバム名 + 読みがな(ソート)タグ
DELETE_FRAMES = [
    "TALB",  # アルバム名
    "TSOT",  # 曲名の読みがな
    "TSOP",  # アーティストの読みがな
    "TSOA",  # アルバムの読みがな
    "TSO2",  # アルバムアーティストの読みがな
    "TSOC",  # 作曲者の読みがな
    "XSOT", "XSOP", "XSOA",  # ID3v2.3非標準ソートタグ
]


def analyze_gain(src: Path) -> tuple[float, float]:
    """ReplayGainのtrack_gain(dB)とtrack_peakを返す"""
    r = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", str(src), "-af", "replaygain", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    gain = peak = None
    for line in r.stderr.splitlines():
        # ffmpegは正のゲインを "+6.45 dB" のように符号付きで出力する
        m = re.search(r"track_gain = ([-+]?[\d.]+) dB", line)
        if m:
            gain = float(m.group(1))
        m = re.search(r"track_peak = ([\d.]+)", line)
        if m:
            peak = float(m.group(1))
    if gain is None:
        raise RuntimeError(f"ReplayGain解析失敗: {src.name}\n{r.stderr[-500:]}")
    return gain, peak if peak is not None else 1.0


def encode(src: Path, dst: Path, gain_db: float) -> None:
    """320kbps CBR MP3にエンコード。ゲインをvolumeフィルタで適用、タグ/アートワーク引き継ぎ"""
    cmd = [
        "ffmpeg", "-hide_banner", "-y", "-i", str(src),
        "-map", "0:a",
        "-af", f"volume={gain_db:.2f}dB",
        "-c:a", "libmp3lame", "-b:a", "320k", "-compression_level", "0",
        "-map_metadata", "0",
        "-id3v2_version", "3",
        # アートワーク(m4aでは映像ストリーム)があればAPICとしてコピー ("0:v?"=無ければ何もしない)
        "-map", "0:v?", "-c:v", "copy", "-disposition:v", "attached_pic",
    ]
    cmd.append(str(dst))
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"エンコード失敗: {src.name}\n{r.stderr[-800:]}")


def clean_tags(dst: Path) -> list[str]:
    """アルバム名・ソートタグ・iTunes系TXXXを削除。削除したフレーム名を返す"""
    audio = MP3(dst, ID3=ID3)
    if audio.tags is None:
        return []
    removed = []
    for key in list(audio.tags.keys()):
        frame_id = key.split(":")[0]
        if frame_id in DELETE_FRAMES or frame_id == "TXXX":
            del audio.tags[key]
            removed.append(key)
    audio.tags.update_to_v23()
    audio.save(v2_version=3)
    return removed


def sanitize(name: str) -> str:
    """ファイル名に使えない文字を全角等に置換"""
    table = {"/": "／", "\\": "＼", ":": "：", "*": "＊", "?": "？",
             '"': "”", "<": "＜", ">": "＞", "|": "｜"}
    for k, v in table.items():
        name = name.replace(k, v)
    return name.strip().rstrip(".")


def output_name(src: Path) -> str:
    """タグから「アーティスト名 - タイトル.mp3」を生成。タグ欠落時は元のファイル名"""
    r = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format_tags=artist,title",
         "-of", "default=noprint_wrappers=1", str(src)],
        capture_output=True, text=True,
    )
    tags = dict(line.split("=", 1) for line in r.stdout.splitlines() if "=" in line)
    artist = tags.get("TAG:artist", "").strip()
    title = tags.get("TAG:title", "").strip()
    if artist and title:
        return sanitize(f"{artist} - {title}") + ".mp3"
    return src.stem + ".mp3"


def read_lyrics(p: Path) -> str:
    """歌詞ファイルを読む。UTF-8(BOM可) → CP932(旧Windows) の順で試し、両方失敗なら明示的にエラー"""
    for enc in ("utf-8-sig", "cp932"):
        try:
            return p.read_text(encoding=enc)
        except UnicodeDecodeError:
            continue
    raise RuntimeError(f"歌詞ファイルの文字コードを判別できません (UTF-8/CP932以外): {p}")


def find_lyrics(src: Path, out_stem: str) -> str | None:
    """txtディレクトリから歌詞ファイルを探して内容を返す。

    探す場所: <入力フォルダ>/txt/ と <入力フォルダの親>/txt/
    探す名前: 元ファイル名 または 出力名「アーティスト - タイトル」 + .txt/.lrc
    """
    dirs = [src.parent / "txt", src.parent.parent / "txt"]
    names = [src.stem, out_stem]
    for d in dirs:
        if not d.is_dir():
            continue
        for name in names:
            for ext in (".txt", ".lrc"):
                p = d / (name + ext)
                if p.exists():
                    return read_lyrics(p)
    return None


def maybe_add_lyrics(src: Path, dst: Path) -> bool:
    """歌詞ファイルがあり、まだUSLTが無ければ埋め込む(再エンコードなし)"""
    lyrics = find_lyrics(src, dst.stem)
    if not lyrics:
        return False
    audio = MP3(dst, ID3=ID3)
    if audio.tags is None or audio.tags.getall("USLT"):
        return False
    audio.tags.add(USLT(encoding=3, lang="jpn", desc="", text=lyrics))
    audio.save(v2_version=3)
    return True


def convert_one(src: Path, out_dir: Path, target_db: float, no_clip: bool,
                produced: set[str]) -> dict:
    dst = out_dir / output_name(src)
    if dst.name in produced:
        # アルバム名を消す運用のため「同アーティスト・同タイトル」は現実に起こる。黙って捨てない
        raise RuntimeError(
            f"出力名が衝突: {dst.name} は今回の実行で別のファイルから生成済み。"
            "アルバム違いの同名曲の可能性 — 別の出力フォルダに分けるかタグを確認して下さい")
    if dst.exists() and dst.stat().st_size > 0:
        # 変換済みでも、後から歌詞ファイルが置かれていれば埋め込む
        added = maybe_add_lyrics(src, dst)
        produced.add(dst.name)
        return {"file": src.name, "skipped": True, "lyrics_added": added,
                "output": str(dst)}
    track_gain, peak = analyze_gain(src)
    gain = track_gain + (target_db - REFERENCE_DB)
    clipped = False
    if no_clip and peak > 0:
        headroom = -20 * math.log10(peak)  # ピークが0dBFSに達するまでの余裕
        if gain > headroom:
            gain = headroom
            clipped = True
    # 一時ファイルに書いてから rename: 中断された変換の残骸を「変換済み」と誤認しない
    tmp = dst.with_suffix(".tmp.mp3")
    try:
        encode(src, tmp, gain)
        removed = clean_tags(tmp)
        tmp.rename(dst)
    finally:
        tmp.unlink(missing_ok=True)
    maybe_add_lyrics(src, dst)
    produced.add(dst.name)
    return {"file": src.name, "gain_db": round(gain, 2), "reduced_for_clip": clipped,
            "removed_tags": removed, "output": str(dst)}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("inputs", nargs="+", help="m4aファイルまたはフォルダ")
    p.add_argument("-o", "--out", required=True, help="出力フォルダ")
    p.add_argument("--target-db", type=float, default=96.0,
                   help="目標音量dB (MP3Gain基準, デフォルト96)")
    p.add_argument("--no-clip", action="store_true",
                   help="音割れする曲はゲインを自動で下げる (mp3gain -k 相当)")
    args = p.parse_args()

    files = []
    for i in args.inputs:
        path = Path(i)
        if path.is_dir():
            files += sorted(path.glob("*.m4a")) + sorted(path.glob("*.M4A"))
        elif path.suffix.lower() == ".m4a":
            files.append(path)
    if not files:
        sys.exit("m4aファイルが見つかりません")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    ok, failed = 0, []
    produced: set[str] = set()
    for i, f in enumerate(files, 1):
        try:
            r = convert_one(f, out_dir, args.target_db, args.no_clip, produced)
            if r.get("skipped"):
                note = " +歌詞埋め込み" if r.get("lyrics_added") else ""
                print(f"[{i}/{len(files)}] スキップ(変換済み) {f.name}{note}")
                ok += 1
                continue
            note = " [クリップ回避で減衰]" if r["reduced_for_clip"] else ""
            print(f"[{i}/{len(files)}] OK {f.name} (gain {r['gain_db']:+.2f}dB){note}")
            ok += 1
        except Exception as e:
            print(f"[{i}/{len(files)}] 失敗 {f.name}: {e}", file=sys.stderr)
            failed.append(f.name)
    print(f"\n完了: {ok}/{len(files)} 曲" + (f" / 失敗: {', '.join(failed)}" if failed else ""))
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
