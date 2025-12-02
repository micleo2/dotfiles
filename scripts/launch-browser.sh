#!/bin/bash

default_browser=$(xdg-settings get default-web-browser)
browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' {~/.local,~/.nix-profile,/usr}/share/applications/$default_browser 2>/dev/null | head -1)

exec setsid uwsm-app -- "$browser_exec" "${@/--private/$private_flag}"
