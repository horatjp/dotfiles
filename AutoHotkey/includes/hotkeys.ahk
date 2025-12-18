; hotkeys.ahk
; 何: 汎用ホットキー集
; なぜ: 追加・削除を1箇所に集約して見通しを良くするため

; キーボードショートカット（編集）
; Ctrl+Backspace: 直前の単語を削除（Ctrl+Shift+Left → Backspace）
^Backspace::Send("^+{Left}{Backspace}")
