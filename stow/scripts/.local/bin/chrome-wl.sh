#!/bin/sh
# Wait Secret Service (gnome-keyring) to be ready.
# Some sites (ChatGPT etc.) can show "logged out" until cookies decrypt; waiting helps.

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25; do
  busctl --user --no-pager --quiet status org.freedesktop.secrets >/dev/null 2>&1 && break
  sleep 0.2
done

# Prefer Wayland; keep DISPLAY if you need XWayland apps, but Chrome itself can run Wayland.
exec env -u DISPLAY google-chrome-stable "$@"

