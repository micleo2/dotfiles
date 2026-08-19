#!/bin/bash

# Firefox must run with --remote-debugging-port for the BiDi path; without it
# the menu silently degrades to the legacy launch/focus path.
FIREFOX_BIDI_PORT=${BIDI_FIREFOX_PORT:-9229}
BIDI_TAB="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/bidi-tab.py"

# Most recently focused window with a class starting with $1 (case-insensitive),
# or empty if none. max_by(focusHistoryID) = last focused wins.
mrw_by_class() {
  hyprctl clients -j | jq -r --arg c "$1" \
    '[ .[] | select((.class // "" | ascii_downcase) | startswith($c)) ] | max_by(.focusHistoryID) | select(. != null) | .address'
}

# Most recently focused window with a class starting with $1 whose title
# contains $2 (both case-insensitive), or empty. A window title only reflects
# the browser's *active* tab, so a hit means that tab is front-most right now.
mrw_by_class_title() {
  hyprctl clients -j | jq -r --arg c "$1" --arg p "$2" \
    '[ .[] | select(((.class // "" | ascii_downcase) | startswith($c)) and ((.title // "" | ascii_downcase) | contains($p))) ] | max_by(.focusHistoryID) | select(. != null) | .address'
}

# Same as mrw_by_class but only counts fully mapped windows (cold starts need
# this: a client can be registered before its window is mapped & focusable).
mrw_by_class_mapped() {
  hyprctl clients -j | jq -r --arg c "$1" \
    '[ .[] | select(((.class // "" | ascii_downcase) | startswith($c)) and .mapped) ] | max_by(.focusHistoryID) | select(. != null) | .address'
}

# Focus a window by address. Hyprland >= 0.55 parses dispatch args as lua;
# older versions need the legacy form.
focus_window() {
  local minor
  minor=$(hyprctl version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f2)
  if [[ ${minor:-0} -ge 55 ]]; then
    hyprctl dispatch "hl.dsp.focus({ window = 'address:$1' })" >/dev/null
  else
    hyprctl dispatch focuswindow "address:$1" >/dev/null
  fi
}

# Show $browser to URL. For firefox, first drive the running instance over
# WebDriver BiDi: activate the site's existing tab if there is one (even a
# background tab), else open exactly one new tab. BiDi focuses the tab but
# not the WM window, so focus the MRW firefox window afterward — immediately,
# no wait for a page title, so a cold open is visible as it loads. On BiDi
# failure (port down, leaked session, timeout -> exit 2 / 124) fall back to
# the legacy title-match / systemd-run path below.
focus_or_open() {
  local browser=$1 pattern=$2 url=$3
  local c p addr pre rc
  c=$(echo "$browser"  | tr '[:upper:]' '[:lower:]')
  p=$(echo "$pattern"  | tr '[:upper:]' '[:lower:]')

  if [[ $c == firefox && -x $BIDI_TAB ]]; then
    timeout 15 python3 "$BIDI_TAB" "$FIREFOX_BIDI_PORT" "$url" 2>/dev/null
    rc=$?
    # 0 = reused tab, 1 = opened new tab: the site's tab is front-most in a
    # firefox window now; anything else -> legacy path.
    if [[ $rc -le 1 ]]; then
      # BiDi already placed the tab in the MRW firefox window; focus it
      # immediately so the user can watch a cold page load.
      addr=$(mrw_by_class "$c")
      if [[ -n $addr ]]; then
        focus_window "$addr"
        return 0
      fi
      echo "bidi-tab succeeded but no $browser window found"
      return 1
    fi
  fi

  addr=$(mrw_by_class_title "$c" "$p")
  if [[ -n $addr ]]; then
    focus_window "$addr"
    return 0
  fi

  pre=$(mrw_by_class "$c")
  # a menu-launched firefox must get the BiDi debug port too, or the next run
  # degrades to the legacy path forever (only for firefox; chromium needs the
  # separate CDP dance and is left untouched)
  local launch=("$browser")
  # two SEPARATE argv elements — one quoted string with a space inside is
  # ONE argument, which firefox silently ignores (port never binds; journal
  # shows it quoted: `"--remote-debugging-port 9229"`). Bash: no commas here.
  [[ $c == firefox ]] && launch+=("--remote-debugging-port" "$FIREFOX_BIDI_PORT")
  systemd-run --user --quiet --collect --unit="browser-menu-$(date +%s%N)" \
    --property=StandardOutput=null --property=StandardError=null \
    "${launch[@]}" "$url"
  if [[ -z $pre ]]; then
    for _ in {1..100}; do
      pre=$(mrw_by_class "$c")
      [[ -n $pre ]] && break
      sleep 0.1
    done
  fi

  [[ -z $pre ]] && { echo "could not find $browser window"; return 1; }
  focus_window "$pre"
}

# menu entries: label|browser|title-match|url
menu=(
  "syncthing|firefox|syncthing|http://localhost:8384/"
  "keybard|chromium|keybard|https://captdeaf.github.io/keybard/"
  "messenger|firefox|messenger|https://www.messenger.com"
)

labels=""
for e in "${menu[@]}"; do labels+="${e%%|*}"$'\n'; done
choice=$(printf '%s' "$labels" | rofi -dmenu -p "Browser")

idx=-1
for i in "${!menu[@]}"; do
  [[ "${menu[$i]%%|*}" == "$choice" ]] && idx=$i
done
[[ $idx -lt 0 ]] && { echo "no match!"; exit 0; }

IFS='|' read -r _label browser pattern url <<< "${menu[$idx]}"
focus_or_open "$browser" "$pattern" "$url"