#!/bin/bash

# Lock the retro shell before the machine suspends.
#
# Holds a logind *delay* inhibitor for as long as it runs, so logind tells
# us about a suspend before doing it and waits (up to InhibitDelayMaxSec)
# for the inhibitor to be released. On PrepareForSleep(true) this asks the
# shell to lock and waits for the session to report secure, then exits,
# which releases the inhibitor. The systemd unit restarts it, which takes
# the inhibitor again for the next time.
#
# Ported from omarchy's omarchy-system-sleep-monitor.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sleep_lock="$here/retro-sleep-lock.sh"

consume_sleep_events() {
  local line

  while IFS= read -r line; do
    if [[ $line == *"boolean true"* ]]; then
      "$sleep_lock"
      return 0
    fi
  done
}

monitor_sleep_events() {
  local monitor_fd monitor_pid status

  coproc SLEEP_EVENTS {
    exec dbus-monitor --system \
      "type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"
  }
  monitor_fd=${SLEEP_EVENTS[0]}
  monitor_pid=$SLEEP_EVENTS_PID

  cleanup_monitor() {
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true
  }
  trap cleanup_monitor EXIT

  consume_sleep_events <&"$monitor_fd"
  status=$?
  cleanup_monitor
  trap - EXIT

  return "$status"
}

case ${1:-} in
  --consume)
    consume_sleep_events
    exit 0
    ;;
  --inhibited)
    monitor_sleep_events
    exit 0
    ;;
esac

exec systemd-inhibit \
  --what=sleep \
  --mode=delay \
  --who=retro-shell \
  --why="Lock screen before suspend" \
  "$here/retro-sleep-monitor.sh" --inhibited
