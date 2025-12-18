#Requires AutoHotkey v2.0
; https://ahkscript.github.io/ja/docs/v2/

#SingleInstance Force
SendMode "Input"

; 分割した設定を読み込み（#Include の相対パスは「このファイルのあるディレクトリ」基準）
#Include "includes/reload_on_save.ahk"
#Include "includes/pointer_scroll_rbutton.ahk"
#Include "includes/hhkb_jp.ahk"
#Include "includes/hotkeys.ahk"
