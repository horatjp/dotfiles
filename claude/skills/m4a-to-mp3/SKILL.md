---
name: m4a-to-mp3
description: m4a(AAC)ファイルをLAME 320kbps CBRのMP3に変換し、MP3Gain方式で音量を96dBに揃え、アルバム名と読みがな(ソート)タグを削除し、「アーティスト名 - タイトル.mp3」にリネームし、用意された歌詞ファイル(.lrc/.txt)があれば埋め込むワークフロー。ユーザーがm4a/AACのMP3変換、音量調整(MP3Gain・ReplayGain・ノーマライズ)、音楽ファイルのタグ削除・整理のいずれかに言及したら必ずこのスキルを使うこと。「昔MusicBeeでやっていた変換」「iTunesの曲をMP3にしたい」のような依頼でも使う。
---

# m4a → MP3 変換 (MusicBee + MP3Gain + タグ整理の再現)

Windows時代の「MusicBee(LAME)で320kbps変換 → MP3Gainで96dB調整 → MP3タグでアルバム名・読みがな削除」を1コマンドで再現するスキル。

## 実行方法

依存関係の確認・準備(初回のみ):
- `ffmpeg` に libmp3lame が必要 (`ffmpeg -encoders | grep lame` で確認)
- `pip install mutagen --break-system-packages`

変換 (`<skill-dir>` はこの SKILL.md があるディレクトリ。カレントディレクトリに依存しないよう絶対パスで指定する):

```bash
python3 <skill-dir>/scripts/convert.py <m4aフォルダまたはファイル...> -o <出力フォルダ>
```

オプション:
- `--target-db 96` — 目標音量。MP3Gainの基準(89dB)からのオフセットで調整される。デフォルト96
- `--no-clip` — 音割れする曲だけゲインを自動で下げる (mp3gain -k 相当)。デフォルトはOFF(昔のMP3Gain運用と同じく96dBをそのまま適用)

## 処理内容(scripts/convert.py が全自動で行う)

1. **音量解析**: ffmpegの `replaygain` フィルタでtrack gain/peakを測定(MP3Gainと同じReplayGainアルゴリズム、基準89dB)
2. **エンコード**: libmp3lame 320kbps CBR・最高品質設定(`-compression_level 0`、LAMEの `-q 0` 相当)。ゲインは `volume` フィルタでエンコード前のPCMに適用するため、MP3Gainの1.5dB刻みと違い正確な値で調整でき、追加劣化もない
3. **タグ整理**: ID3v2.3で書き出し後、以下を削除
   - アルバム名 (TALB)
   - 全ソートタグ=読みがな (TSOT/TSOP/TSOA/TSO2/TSOC)
   - iTunes系のTXXXフレーム (iTunNORM, iTunSMPB, account_id 等の不要情報。購入者メールアドレスもここで消える)
   - 曲名・アーティスト・アルバムアーティスト・作曲者・ジャンル・トラック番号・年・アートワークは保持
4. **ファイル名**: タグから「アーティスト名 - タイトル.mp3」を生成 (OSで使えない文字は全角に置換。タグ欠落時は元のファイル名を使用)
5. **歌詞埋め込み**: `txt` ディレクトリ(入力フォルダ内またはその親、例: `music/txt/`)に歌詞ファイルが存在する場合のみUSLT(歌詞)タグとして埋め込む。ファイル名は「元のm4a名」か「アーティスト名 - タイトル」+ `.txt`/`.lrc`。変換済みのMP3にも、後から歌詞を置いて再実行すれば再エンコードなしで埋め込まれる(USLTが既にある場合は上書きしない)。歌詞ファイルはユーザーが用意したものだけを使うこと — 歌詞サイトからの自動取得・転載はしない(著作権)

## 検証

変換後にサンプル数曲で確認するとよい:

```bash
# ビットレート・コーデック確認 (320000 / mp3 になっているはず)
ffprobe -v error -show_entries format=bit_rate -select_streams a \
  -show_entries stream=codec_name -of default=noprint_wrappers=1 <出力.mp3>

# 音量確認: 出力のtrack_gainが (89 - 目標dB) に近ければ正しい (96dBなら約 -7.0)
ffmpeg -i <出力.mp3> -af replaygain -f null - 2>&1 | grep track_gain

# タグ確認: album やソートタグが出てこないこと
ffprobe -v error -show_entries format_tags -of default=noprint_wrappers=1 <出力.mp3>
```

## 注意点

- 96dBは高めの目標音量なので、多くの曲でピークが0dBFSを超えうる(MP3Gainで96dBにしていた頃と同じ挙動)。音割れが気になる場合は `--no-clip` を提案する
- 出力ファイル名は「アーティスト名 - タイトル.mp3」。前回実行分など同名出力が既に存在する場合はスキップされる(再変換したいときは既存ファイルを消すか別フォルダへ)。ただし**同一実行内**で別のm4aが同名になった場合(アルバム違いの同名曲など)は黙って捨てずエラーとして報告される
- 歌詞ファイルはUTF-8またはCP932(旧Windows)で読み込む。どちらでも読めない場合はその曲がエラーになる
- 削除タグを変えたい場合は `scripts/convert.py` の `DELETE_FRAMES` を編集
