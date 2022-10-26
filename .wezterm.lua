local wezterm = require 'wezterm'
return {
   color_scheme = "MonokaiDark (Gogh)",

   font = wezterm.font "Mgen+ 1mn",
   font_size = 12.0,

   initial_cols = 140,
   initial_rows = 35,
   scrollback_lines = infinite,
   enable_scroll_bar = true,
   use_ime = true,
   window_background_opacity = 0.85,
}
