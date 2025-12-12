local wezterm = require 'wezterm'
return {
--   color_scheme = "MonokaiDark (Gogh)",
--   color_scheme = "OneHalfDark",
--   color_scheme = "nord",
--   color_scheme = "Solarized Dark Higher Contrast",
   color_scheme = "Monokai Vivid",
   
   font = wezterm.font "Mgen+ 1mn",
   font_size = 11.0,

   initial_cols = 120,
   initial_rows = 35,
   enable_scroll_bar = true, 
   scrollback_lines = infinite,
   enable_scroll_bar = true,
   use_ime = true,
   window_background_opacity = 0.75,
}
