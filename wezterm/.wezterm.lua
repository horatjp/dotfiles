local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Default shell: WSL (Debian)
-- - - - - - - - - - - - - - - - - - - - - - - -
config.default_domain = "WSL:Debian"

config.wsl_domains = {
  {
    name = "WSL:Debian",
    distribution = "Debian",
    default_cwd = "~",
  },
}

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Font
-- - - - - - - - - - - - - - - - - - - - - - - -
config.font = wezterm.font("HackGen Console NF")
config.font_size = 11.0

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
}
config.window_background_opacity = 0.9
config.window_decorations = "TITLE | RESIZE"
config.initial_cols = 100
config.initial_rows = 30

-- IME (日本語入力)
config.use_ime = true

-- Tab bar
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false

-- Live config reload
config.automatically_reload_config = true

-- Extract Linux path from WSL URL (strips /wsl.localhost/Distro prefix)
local function wsl_cwd(pane)
  local cwd_url = pane:get_current_working_dir()
  if not cwd_url then return nil end
  local path = cwd_url.file_path
  return path:match("^/wsl[^/]*/[^/]+(.+)") or (path:match("^/home/") and path) or nil
end

-- - - - - - - - - - - - - - - - - - - - - - - -
-- Key bindings
-- - - - - - - - - - - - - - - - - - - - - - - -
config.keys = {
  -- Split pane: horizontal (right) - inherit WSL cwd
  {
    key = "d", mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain", cwd = wsl_cwd(pane) }),
        pane
      )
    end),
  },
  -- Split pane: vertical (down) - inherit WSL cwd
  {
    key = "e", mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        wezterm.action.SplitVertical({ domain = "CurrentPaneDomain", cwd = wsl_cwd(pane) }),
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
  -- Move between tabs
  { key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
}

return config
