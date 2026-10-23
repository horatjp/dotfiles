---
name: m4a-to-mp3
description: m4a(AAC)ファイルをLAME 320kbps CBRのMP3に変換し、音量を-11.0 LUFS(EBU R128)に揃え(旧方式のMP3Gain 96dBも選択可)、アルバム名と読みがな(ソート)タグを削除し、「アーティスト名 - タイトル.mp3」にリネームし、用意された歌詞ファイル(.lrc/.txt)があれば埋め込むワークフロー。ユーザーがm4a/AACのMP3変換、音量調整(MP3Gain・ReplayGain・ノーマライズ)、音楽ファイルのタグ削除・整理のいずれかに言及したら必ずこのスキルを使うこと。「昔MusicBeeでやっていた変換」「iTunesの曲をMP3にしたい」のような依頼でも使う。
---

# m4a → MP3 変換 (MusicBee + MP3Gain + タグ整理の再現)

Windows時代の「MusicBee(LAME)で320kbps変換 → MP3Gainで96dB調整 → MP3タグでアルバム名・読みがな削除」を1コマンドで再現するスキル。

音量の基準は2026-09-13にNASライブラリを ReplayGain 96dB から **-11.0 LUFS** に移行したため、既定は -11.0 LUFS。ReplayGain(1991年頃のアルゴリズム)は現代の高音圧マスタリングを評価しきれず、96dBに揃えても曲ごとに体感音量がばらついていたのが理由。

## 実行方法

依存関係の確認・準備(初回のみ):
- `ffmpeg` に libmp3lame が必要 (`ffmpeg -encoders | grep lame` で確認)
- `pip install mutagen --break-system-packages`

変換 (`<skill-dir>` はこの SKILL.md があるディレクトリ。カレントディレクトリに依存しないよう絶対パスで指定する):

```bash
python3 <skill-dir>/scripts/convert.py <m4aフォルダまたはファイル...> -o <出力フォルダ>
```

オプション:
- `--target-lufs -11` — 目標ラウドネス(LUFS)。デフォルト -11.0 (NASライブラリの基準)
- `--target-db 96` — 旧方式。ReplayGain/MP3Gainの基準(89dB)からのオフセットで調整する。指定するとLUFSの代わりにこちらを使う(`--target-lufs` と同時指定は不可)
- `--no-clip` — 音割れする曲だけゲインを自動で下げる (mp3gain -k 相当)。デフォルトはOFF

## 処理内容(scripts/convert.py が全自動で行う)

1. **音量解析**: ffmpegの `ebur128` フィルタで統合ラウドネス(LUFS)とサンプルピークを測定。`--target-db` 指定時は `replaygain` フィルタでtrack gain/peakを測定(MP3Gainと同じReplayGainアルゴリズム、基準89dB)
2. **エンコード**: libmp3lame 320kbps CBR・最高品質設定(`-compression_level 0`、LAMEの `-q 0` 相当)。ゲインは `volume` フィルタでエンコード前のPCMに適用するため、MP3Gainの1.5dB刻みと違い正確な値で調整でき、追加劣化もない
3. **タグ整理**: ID3v2.3で書き出し後、以下を削除
   - アルバム名 (TALB)
   - 全ソートタグ=読みがな (TSOT/TSOP/TSOA/TSO2/TSOC)
   - iTunes系のTXXXフレーム (iTunNORM, iTunSMPB, account_id 等の不要情報。購入者メールアドレスもここで消える)
   - 曲名・アーティスト・アルバムアーティスト・作曲者・ジャンル・トラック番号・年・アートワークは保持
4. **ファイル名**: タグから「アーティスト名 - タイトル.mp3」を生成 (OSで使えない文字は全角に置換。タグ欠落時は元のファイル名を使用)
5. **歌詞埋め込み**: 歌詞ファイルが存在する場合のみUSLT(歌詞)タグとして埋め込む。置き場所は **m4aと同じフォルダ(推奨)**、または `txt` ディレクトリ(入力フォルダ内またはその親、例: `music/txt/`)。同居を先に探す。ファイル名は「元のm4a名」か「アーティスト名 - タイトル」+ `.txt`/`.lrc`。変換済みのMP3にも、後から歌詞を置いて再実行すれば再エンコードなしで埋め込まれる(USLTが既にある場合は上書きしない)。歌詞ファイルはユーザーが用意したものだけを使うこと — 歌詞サイトからの自動取得・転載はしない(著作権)

## 検証

変換後にサンプル数曲で確認するとよい:

```bash
# ビットレート・コーデック確認 (320000 / mp3 になっているはず)
ffprobe -v error -show_entries format=bit_rate -select_streams a \
  -show_entries stream=codec_name -of default=noprint_wrappers=1 <出力.mp3>

# 音量確認: 出力の統合ラウドネス I が目標(既定 -11.0 LUFS)に近ければ正しい
ffmpeg -nostats -i <出力.mp3> -af ebur128 -f null - 2>&1 | grep -A1 'Integrated loudness'
# (--target-db 使用時) track_gainが (89 - 目標dB) に近ければ正しい (96dBなら約 -7.0)
ffmpeg -i <出力.mp3> -af replaygain -f null - 2>&1 | grep track_gain

# タグ確認: album やソートタグが出てこないこと
ffprobe -v error -show_entries format_tags -of default=noprint_wrappers=1 <出力.mp3>
```

## 注意点

- -11 LUFS / 96dB はどちらも高めの目標音量なので、音圧の低い曲を持ち上げるとピークが0dBFSを超えうる。音割れが気になる場合は `--no-clip` を提案する
- NASの既存ライブラリは -11.0 LUFS 基準。旧方式の `--target-db 96` で変換すると、ライブラリより最大1dB程度大きくなり曲ごとのばらつきも残る
- 出力ファイル名は「アーティスト名 - タイトル.mp3」。前回実行分など同名出力が既に存在する場合はスキップされる(再変換したいときは既存ファイルを消すか別フォルダへ)。ただし**同一実行内**で別のm4aが同名になった場合(アルバム違いの同名曲など)は黙って捨てずエラーとして報告される
- 歌詞ファイルはUTF-8またはCP932(旧Windows)で読み込む。どちらでも読めない場合はその曲がエラーになる
- 削除タグを変えたい場合は `scripts/convert.py` の `DELETE_FRAMES` を編集
