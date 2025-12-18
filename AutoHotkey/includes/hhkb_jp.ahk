; hhkb_jp.ahk
; 何: HHKB (JP配列) 向けのマウス操作レイヤ
; なぜ: キーボードから手を離さずにポインタ移動/スクロールするため
;
; レイヤキー: 半角/全角 (sc029)
; - このキーを単体で使わない前提なので、単押しは無効化します。
; - もし環境によってキー名が違う場合は、AHKの Key history で vk/sc を確認して調整してください。

; ========================================
; 設定値
; ========================================
MouseStepPx := 8       ; 1回の移動量（px）
MouseSpeed := 0        ; 0=瞬間移動
WheelNotches := 1      ; 1回のスクロール段数

; グローバル変数
LayerActive := false
LastToggleTime := 0
ToggleDebounce := 200  ; トグルのデバウンス時間（ms）

; 半角/全角でトグル切り替え
sc029:: {
    global LayerActive, LastToggleTime, ToggleDebounce
    currentTime := A_TickCount

    ; デバウンス: 短時間の連続押下を無視
    if (currentTime - LastToggleTime < ToggleDebounce) {
        return
    }

    LayerActive := !LayerActive
    LastToggleTime := currentTime

    ; 状態を表示
    if (LayerActive) {
        ToolTip("🖱️ マウスレイヤー ON")
        SetTimer(() => ToolTip(), -1500)  ; 1.5秒後に消す
    } else {
        ToolTip("⌨️ 通常モード")
        SetTimer(() => ToolTip(), -1000)  ; 1秒後に消す
    }
}

; レイヤーが有効かチェック
IsLayerActive() {
    global LayerActive
    return LayerActive
}

#HotIf IsLayerActive()

; マウス移動（vi風）- キーリピート対応
j:: {
    global LayerActive
    Loop {
        if !LayerActive
            break
        MouseMove(-MouseStepPx, 0, MouseSpeed, "R")
        Sleep(30)
        if !GetKeyState("j", "P")
            break
    }
}

k:: {
    global LayerActive
    Loop {
        if !LayerActive
            break
        MouseMove(0, MouseStepPx, MouseSpeed, "R")
        Sleep(30)
        if !GetKeyState("k", "P")
            break
    }
}

l:: {
    global LayerActive
    Loop {
        if !LayerActive
            break
        MouseMove(MouseStepPx, 0, MouseSpeed, "R")
        Sleep(30)
        if !GetKeyState("l", "P")
            break
    }
}

i:: {
    global LayerActive
    Loop {
        if !LayerActive
            break
        MouseMove(0, -MouseStepPx, MouseSpeed, "R")
        Sleep(30)
        if !GetKeyState("i", "P")
            break
    }
}

; スクロール - キーリピート対応
u:: {
    global LayerActive
    Loop {
        if !LayerActive
            break
        Click "WheelUp", WheelNotches
        Sleep(100)
        if !GetKeyState("u", "P")
            break
    }
}

o:: {
    global LayerActive
    Loop {
        if !LayerActive
            break
        Click "WheelDown", WheelNotches
        Sleep(100)
        if !GetKeyState("o", "P")
            break
    }
}

; クリック操作
; 半角/全角+h=左クリック
h::Click "Left"

; 半角/全角+;=右クリック
SC027::Click "Right"

#HotIf
