--
--  WezTerm用設定ファイル
--

-- おまじない
local wezterm = require 'wezterm'
local config = {}

--  専用関数　使わなくてもいいけど
local function Set(key, value)
  config[key] = value
end

-- === toggles（ここだけ触ればOK）===
local EXPERIMENT_WEBGPU = true          -- falseでOpenGL
local EXPERIMENT_LIGHT_FREETYPE = true  -- falseで無効
local EXPERIMENT_DARK_BG = true         -- falseでMonokai背景そのまま
local EXPERIMENT_BG_GRADIENT = false


--  カラースキーム
Set("color_scheme", "Monokai Dark (Gogh)") -- 上で定義したSetの使い方例
--   config.color_scheme = "OneHalfDark"
--   config.color_scheme = "nord"
--   config.color_scheme = "Solarized Dark Higher Contrast"
--   config.color_scheme = "Monokai Vivid"

config.colors = config.colors or {}
-- config.colors.foreground = "#D8D8D8"
-- 背景だけ沈める（真っ黒より少しだけ色味ある黒が見やすい）
if EXPERIMENT_DARK_BG then
    config.colors = {
        background = "#070807",
    }
end

-- フォント設定
config.font = wezterm.font_with_fallback({
  { family = "MyricaM M", weight = "Book" },

  -- 鍵アイコン等（\uf023）は Solid 側に入ってることが多い
  "Font Awesome 7 Free Solid",
  "Font Awesome 7 Free",
  "Font Awesome 7 Brands",

  "Noto Sans Mono CJK JP",
  "Noto Sans CJK JP",
  "Noto Color Emoji",
  "JetBrains Mono",
})

config.font_size = 12.0

--  Myrica系は行間を少し増やすと気持ちいいことある。
config.line_height = 1.00
config.cell_width = 1.00  -- 字間。必要なら 0.95〜1.05で微調整

--  “太字を使わない”で見た目を均一にする（テーマによっては激変）
config.bold_brightens_ansi_colors = false

--  タイトルバー＋リサイズ可
--config.window_decorations = "RESIZE"

--  タブにアイコンつける（演出＋実用）
config.use_fancy_tab_bar = true

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

config.show_tab_index_in_tab_bar = true
config.tab_max_width = 32

--  背景にグラデーション
if EXPERIMENT_BG_GRADIENT == true then
config.window_background_gradient = {
  orientation = "Vertical",
  colors = { "#050605", "#0B0F0B" },
}
end

--  起動時のフェード
config.animation_fps = 60
config.cursor_blink_ease_in = "EaseIn"
config.cursor_blink_ease_out = "EaseOut"


-- 列数
config.initial_cols = 120
-- 行数
config.initial_rows = 45

-- スクロール
config.enable_scroll_bar = true
config.scrollback_lines = 20000

-- 変換中表示をOS/IME側に任せる
config.ime_preedit_rendering = "System"
config.use_ime = true

-- 透過は0.88で「雰囲気」残しつつ読める寄り
config.window_background_opacity = 0.90

-- 余白（見た目と可読性が上がる）
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }

-- ベル系うるさいのを切る
config.audible_bell = "Disabled"
config.visual_bell = { fade_in_function = "EaseIn", fade_in_duration_ms = 0, fade_out_function = "EaseOut", fade_out_duration_ms = 0 }

-- カーソル点滅を止めるときは０（好み）
config.cursor_blink_rate = 400
config.default_cursor_style = "BlinkingBar"

--  コピーしたら選択解除。「ダブルクリックで単語選択」の境界を賢くするやつ
config.selection_word_boundary = " \t\n{}[]()\"'`,;:="

-- よくあるコピペ（Linuxでも楽）
config.keys = {
    { key = "C", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo "Clipboard" },
    { key = "V", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom "Clipboard" },
}
--  タブ
for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "ALT",
    action = wezterm.action.ActivateTab(i - 1),
  })
end


--  リロードキー（設定いじりが楽）
config.keys = config.keys or {}
table.insert(config.keys, { key = "R", mods = "CTRL|SHIFT", action = wezterm.action.ReloadConfiguration })

-- 描画
config.front_end = EXPERIMENT_WEBGPU and "WebGpu" or "OpenGL"   -- ダメなら "OpenGL" に戻す

if EXPERIMENT_LIGHT_FREETYPE then
    config.freetype_load_target = "Light"    --  "Normal"（デフォルト。標準のヒンティング）
                                              --  "Light"（軽めのヒンティング。輪郭は自然寄り、ちょいフワることも）

    config.freetype_render_target = "Light"
    --  config.freetype_render_target = "HorizontalLcd"     --  合うならメッチャくっきり
end

--  フレームレート
config.max_fps = 60




-- 設定反映
return config
