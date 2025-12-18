; pointer_scroll_rbutton.ahk
; 何: RButton（マウスの右側面ボタン）押下＋マウス移動でスクロールする
; なぜ: 片手操作でのスクロールを快適にするため（短押しは通常のブラウザバック）

; ========================================
; 設定値
; ========================================
ScrollSpeed := 30              ; スクロール速度（高速設定）
ScrollThreshold := 10          ; スクロール開始判定の移動距離
ClickTimeThreshold := 200      ; 右クリックとみなす最大時間（ミリ秒）

; ========================================
; グローバル変数
; ========================================
IsScrolling := false           ; スクロール中フラグ
StartMouseX := 0               ; 右ボタン押下時のX座標
StartMouseY := 0               ; 右ボタン押下時のY座標
StartTime := 0                 ; 右ボタン押下時刻
HasMoved := false              ; マウス移動フラグ

; ========================================
; RButton押下時
; ========================================
RButton:: {
    global IsScrolling, StartMouseX, StartMouseY, StartTime, HasMoved
    global ScrollSpeed, ScrollThreshold, ClickTimeThreshold

    MouseGetPos(&StartMouseX, &StartMouseY)
    StartTime := A_TickCount
    IsScrolling := false
    HasMoved := false

    ; RButtonが離されるまでループ
    while GetKeyState("RButton", "P")
    {
        MouseGetPos(&CurrentX, &CurrentY)
        DeltaX := CurrentX - StartMouseX
        DeltaY := CurrentY - StartMouseY

        ; 一定距離以上動いたらスクロールモードに移行
        if (!IsScrolling && (Abs(DeltaX) > ScrollThreshold || Abs(DeltaY) > ScrollThreshold))
        {
            IsScrolling := true
            HasMoved := true
        }

        ; スクロール処理
        if (IsScrolling)
        {
            ; 垂直スクロール（上下）
            if (Abs(DeltaY) > 2)
            {
                ScrollAmount := Round(DeltaY / ScrollSpeed)
                if (ScrollAmount != 0)
                {
                    if (ScrollAmount > 0) {
                        Loop ScrollAmount {
                            Send("{WheelDown}")
                        }
                    }
                    else {
                        Loop Abs(ScrollAmount) {
                            Send("{WheelUp}")
                        }
                    }

                    ; マウスカーソルを元の位置に戻す
                    MouseMove(StartMouseX, StartMouseY, 0)
                }
            }

            ; 水平スクロール（左右）
            if (Abs(DeltaX) > 2)
            {
                ScrollAmount := Round(DeltaX / ScrollSpeed)
                if (ScrollAmount != 0)
                {
                    if (ScrollAmount > 0) {
                        Loop ScrollAmount {
                            Send("{WheelRight}")
                        }
                    }
                    else {
                        Loop Abs(ScrollAmount) {
                            Send("{WheelLeft}")
                        }
                    }

                    ; マウスカーソルを元の位置に戻す
                    MouseMove(StartMouseX, StartMouseY, 0)
                }
            }
        }

        Sleep(10)
    }

    ; RButtonが離された時の処理
    ElapsedTime := A_TickCount - StartTime

    ; スクロールしていなくて、短時間の押下なら通常のブラウザバック
    if (!HasMoved && ElapsedTime < ClickTimeThreshold)
    {
        Send("{RButton}")
    }
}

