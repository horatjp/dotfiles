local wezterm = require("wezterm")
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Default shell: WSL (Debian) on Windows, zsh on macOS/Linux
-- - - - - - - - - - - - - - - - - - - - - - - -
if is_windows then
  config.default_domain = "WSL:Debian"
  config.wsl_domains = {
    {
      name = "WSL:Debian",
      distribution = "Debian",
      default_cwd = "~",
    },
  }
end

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Font
-- - - - - - - - - - - - - - - - - - - - - - - -
config.font = wezterm.font("HackGen Console NF")
config.font_size = is_windows and 11.0 or 15.0

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Appearance
-- - - - - - - - - - - - - - - - - - - - - - - -
config.color_scheme = "OneHalfDark"
config.colors = {
  brights = {
    "#636d83",  -- 8: bright black / dark gray (明るく)
    "#e06c75",  -- 9: bright red
    "#98c379",  -- 10: bright green
    "#e5c07b",  -- 11: bright yellow
    "#61afef",  -- 12: bright blue
    "#c678dd",  -- 13: bright magenta
    "#56b6c2",  -- 14: bright cyan
    "#ffffff",  -- 15: bright white
  },
  -- タイトルバーと一体化したタブバーの色(青みを抜いた灰色にして、OneHalfDark の本体 #282c34 と分ける)。
  -- タブの背景はバーと同じにして1枚の帯に見せ、今のタブかどうかは文字の明るさで見分ける
  tab_bar = {
    inactive_tab_edge = "#2e3035",
    active_tab = { bg_color = "#2e3035", fg_color = "#b4b8bf" },
    inactive_tab = { bg_color = "#2e3035", fg_color = "#757a84" },
    inactive_tab_hover = { bg_color = "#2e3035", fg_color = "#b4b8bf" },
  },
}
config.window_background_opacity = 0.9
-- OS 標準のタイトルバーは色を変えられないため消し、閉じる・最小化・最大化のボタンをタブバーに入れる
-- (macOS は標準の信号ボタンをそのまま移す。Windows は WezTerm が Windows 風に描く)
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_frame = {
  font = wezterm.font({ family = "HackGen Console NF", weight = "Bold" }),
  font_size = is_windows and 11.0 or 15.0, -- 端末の本体と同じ大きさ。バーの高さも文字に合わせて高くなる(文字の高さの 1.75 倍)
  -- バーは不透明にする。WezTerm 20240203 はこの色を「バー全体」と「左側のボタンとタブをまとめた部分」に
  -- 重ねて塗るため、半透明にすると左側だけ二重になって暗くなる。
  -- 昔風のタブバー(use_fancy_tab_bar = false)ならむらなく透かせるが、高さが端末の1行ぶんしかなく窮屈になる
  active_titlebar_bg = "#2e3035",
  inactive_titlebar_bg = "#2e3035",
}
config.initial_cols = 100
config.initial_rows = 30

-- IME (日本語入力)
config.use_ime = true

-- Tab bar
-- タイトルバーを兼ねるため、上端に常に出す(隠すとボタンとウィンドウを掴む場所が無くなる)
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false

-- Live config reload
config.automatically_reload_config = true

-- Extract cwd from pane (strips /wsl.localhost/Distro prefix on Windows)
local function get_cwd(pane)
  local cwd_url = pane:get_current_working_dir()
  if not cwd_url then return nil end
  local path = cwd_url.file_path
  if is_windows then
    return path:match("^/wsl[^/]*/[^/]+(.+)") or (path:match("^/home/") and path) or nil
  end
  return path
end

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Tab title
-- - - - - - - - - - - - - - - - - - - - - - - -
local function get_title(pane)
  local cwd = pane.current_working_dir
  if cwd then
    return cwd.file_path:match("([^/\\]+)[/\\]?$") or "shell"
  end
  return "shell"
end

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local title = get_title(tab.active_pane)
  -- 先頭にフォルダのアイコン(Nerd Font)を付ける
  return "  " .. wezterm.nerdfonts.md_folder .. " " .. wezterm.truncate_right(title, max_width - 6) .. "  "
end)

wezterm.on("format-window-title", function(tab)
  return get_title(tab.active_pane)
end)

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Key bindings
-- - - - - - - - - - - - - - - - - - - - - - - -
config.keys = {
  -- Split pane: horizontal (right) - inherit cwd
  {
    key = "d", mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain", cwd = get_cwd(pane) }),
        pane
      )
    end),
  },
  -- Split pane: vertical (down) - inherit cwd
  {
    key = "e", mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        wezterm.action.SplitVertical({ domain = "CurrentPaneDomain", cwd = get_cwd(pane) }),
        pane
      )
    end),
  },
  -- Move between panes
  { key = "h", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
  -- New tab
  { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  -- Close tab / pane
  { key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  -- Copy mode
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.ActivateCopyMode },
  -- QuickSelect（画面上のURL・パス・ハッシュ等をラベル選択でコピー）
  { key = "Enter", mods = "SUPER", action = wezterm.action.QuickSelect },
  -- QuickSelect で URL だけを対象にし、選んだものを既定のブラウザで開く
  {
    key = "o", mods = "SUPER",
    action = wezterm.action.QuickSelectArgs({
      label = "open url",
      patterns = { "https?://\\S+" },
      action = wezterm.action_callback(function(window, pane)
        local url = window:get_selection_text_for_pane(pane)
        wezterm.open_with(url)
      end),
    }),
  },
  -- QuickSelect で「ファイル:行(:列)」だけを対象にしてコピー（例: src/foo.ts:42）
  -- 英字の拡張子を必須にして時刻や host:port を除外。既定の QuickSelect には混ぜない
  {
    key = "l", mods = "SUPER",
    action = wezterm.action.QuickSelectArgs({
      label = "copy file:line",
      patterns = { "[\\w./-]+\\.[A-Za-z]\\w*:\\d+(?::\\d+)?" },
    }),
  },
  -- Move between tabs
  { key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
  -- Shift+Enter: 改行（AI CLI 向け）
  -- ESC+CR（Meta+Enter）を送る。Claude Code / Codex などはこれを改行として扱い、
  -- tmux 経由でも素通しされる（kitty keyboard protocol は tmux 側の対応が要るため使わない）
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\x1b\r") },
}

-- Paste from clipboard(Windows のみ。macOS は Cmd+V があり、Ctrl+V は nvim / tmux の矩形選択に残す)
if is_windows then
  table.insert(config.keys, { key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") })
end

return config
