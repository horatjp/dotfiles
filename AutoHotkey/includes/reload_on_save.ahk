; reload_on_save.ahk
; 何: AutoHotkeyスクリプト編集時の自動リロード（Ctrl+S）
; なぜ: 編集→保存の流れで、手動リロード無しに反映するため

#HotIf WinActive(".ahk")
^s::
{
    AFKFileTime    := FileGetTime(A_ScriptFullPath, "M") ; M＝修正時間
    AFKFileTimeFmt := FormatTime(AFKFileTime, "yyyy/MM/dd HH:mm:ss") ; 日時表示形式を修正
    Send("^s") ; 更新前のファイル日時を取得したい為、ホットキーにチルダ(~)を付けずにここでSend("^s")する。
    Sleep(250)
    AFKFileTime2    := FileGetTime(A_ScriptFullPath, "M")
    AFKFileTimeFmt2 := FormatTime(AFKFileTime2, "yyyy/MM/dd HH:mm:ss")
    MsgBox(A_ScriptFullPath "をReloadします`n変更前: " AFKFileTimeFmt "`n変更後: " AFKFileTimeFmt2)
    Reload()
}
#HotIf

