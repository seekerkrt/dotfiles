#!/usr/bin/env bash
set -Eeuo pipefail

sudo KEYLEDS_DEVICE=/dev/hidraw2 keyledsctl set-leds all=aaccff
