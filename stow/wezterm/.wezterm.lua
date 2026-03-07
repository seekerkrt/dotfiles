--
--  WezTerm用設定ファイル
--

local wezterm = require 'wezterm'
local config = {}

local function Set(key, value)
    config[key] = value
end

-- === toggles（ここだけ触ればOK）===
local EXPERIMENT_WEBGPU = false         -- falseでOpenGL
local EXPERIMENT_LIGHT_FREETYPE = true -- falseで無効
local EXPERIMENT_DARK_BG = true        -- falseでMonokai背景そのまま
local EXPERIMENT_BG_GRADIENT = false
local TRANSPARENT = false    --  true=0.70 / false=0.88


-- =============================================================================
-- Theme
-- =============================================================================
Set("color_scheme", "Monokai Dark (Gogh)")

config.colors = config.colors or {}

-- 背景だけ沈める（colorsテーブルを丸ごと潰さない）
if EXPERIMENT_DARK_BG then
    config.colors.background = "#070807"
end

-- （必要なら）文字色を少し持ち上げる
-- config.colors.foreground = "#D8D8D8"

-- 背景にグラデーション（演出）
if EXPERIMENT_BG_GRADIENT then
    config.window_background_gradient = {
        orientation = "Vertical",
        colors = { "#050605", "#0B0F0B" },
    }
end

-- =============================================================================
-- Font
-- =============================================================================
config.font = wezterm.font_with_fallback({
    { family = "MyricaM M", weight = "Book" },

    -- 鍵アイコン等（\uf023）対策
    "Font Awesome 7 Free Solid",
    "Font Awesome 7 Free",
    "Font Awesome 7 Brands",

    "Noto Sans Mono CJK JP",
    "Noto Sans CJK JP",
    "Noto Color Emoji",
    "JetBrains Mono",
})

config.font_size = 12.0
config.line_height = 1.00
config.cell_width = 1.00

-- 太字の見え方を抑える
config.bold_brightens_ansi_colors = false

-- =============================================================================
-- Tabs
-- =============================================================================
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.show_tab_index_in_tab_bar = true
config.tab_max_width = 32

-- =============================================================================
-- Window / UI
-- =============================================================================
config.initial_cols = 120
config.initial_rows = 45

config.enable_scroll_bar = true
config.scrollback_lines = 20000

config.window_background_opacity = TRANSPARENT and 0.70 or 0.88
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }

-- 起動/カーソル演出（好み）
config.animation_fps = 60
config.cursor_blink_ease_in = "EaseIn"
config.cursor_blink_ease_out = "EaseOut"

-- =============================================================================
-- IME
-- =============================================================================
config.use_ime = true
config.ime_preedit_rendering = "System"

-- =============================================================================
-- Bells
-- =============================================================================
config.audible_bell = "Disabled"
config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 0,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 0,
}

-- =============================================================================
config.cursor_blink_rate = 400
config.default_cursor_style = "BlinkingBar"

-- 単語選択境界
config.selection_word_boundary = " \t\n{}[]()\"'`,;:="

-- =============================================================================
-- Clipboard / Mouse
-- =============================================================================
config.mouse_bindings = {
  -- 左ボタンで選択→指を離した瞬間に Clipboard へコピー（= copy-on-select 相当）
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor "Clipboard",
    -- デフォルトは PrimarySelection なので、それを Clipboard に変えるのが肝
  },

  -- 右クリックで貼り付け（Clipboard）
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.PasteFrom "Clipboard",
  },
}

-- =============================================================================
-- Keys
-- =============================================================================
config.keys = {
    { key = "C", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo "Clipboard" },
    { key = "V", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom "Clipboard" },
    { key = "R", mods = "CTRL|SHIFT", action = wezterm.action.ReloadConfiguration },
    { key = "e", mods = "ALT", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
    { key = "o", mods = "ALT", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "h", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Left" },
    { key = "l", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Right" },
    { key = "k", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Up" },
    { key = "j", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Down" },
}

for i = 1, 8 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "ALT",
        action = wezterm.action.ActivateTab(i - 1),
    })
end

-- =============================================================================
-- Render / Perf
-- =============================================================================
config.front_end = EXPERIMENT_WEBGPU and "WebGpu" or "OpenGL"
config.max_fps = 60

if EXPERIMENT_LIGHT_FREETYPE then
    config.freetype_load_target = "Light"
    config.freetype_render_target = "Light"
end

--  設定反映（忘れずにリターン）
return config
