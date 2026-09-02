#!/bin/bash

# Ask the retro shell to lock and wait until the session lock is secure.
#
# Overrunning the budget is the failure this whole path exists to prevent:
# logind stops honouring the inhibitor and suspends mid-lock. Every call
# below is bounded by what is left of the budget, so the deadline enforces
# itself rather than depending on an estimate of how long a step ought to
# take.
#
# Ported from omarchy's omarchy-system-sleep-lock.

budget_cap_ms=12000
lock_timeout_ms=1000
status_timeout_ms=500
poll_interval=0.1

shell_ipc() {
  qs -c retro ipc call "$@"
}

# logind decides how long a delay inhibitor may hold the machine, so ask
# rather than assume. Leaving logind a fifth of its own window to deliver
# PrepareForSleep and act on the release gives 4s at the 5s default and 12s
# with the 15s drop-in from install/logind-inhibit-delay.conf.
derive_budget_ms() {
  local window
  window=$(timeout --kill-after=0.1s 1s busctl get-property \
    org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager InhibitDelayMaxUSec 2>/dev/null)
  window=${window##* }

  [[ $window =~ ^[0-9]+$ ]] && (( window > 0 )) || window=5000000
  window=$((window / 1000))

  # Never leave logind less than a second, however small its window is.
  window=$((window - (window / 5 > 1000 ? window / 5 : 1000)))

  (( window < budget_cap_ms )) && echo "$window" || echo "$budget_cap_ms"
}

budget_ms=${1:-$(derive_budget_ms)}
if [[ ! $budget_ms =~ ^[0-9]+$ ]] || (( budget_ms < 1 || budget_ms > budget_cap_ms )); then
  budget_ms=$(derive_budget_ms)
fi

# EPOCHREALTIME renders with the locale's decimal separator, so drop every
# non-digit rather than assuming a period.
deadline_ms=$((10#${EPOCHREALTIME//[!0-9]/} / 1000 + budget_ms))

remaining_ms() {
  echo $((deadline_ms - 10#${EPOCHREALTIME//[!0-9]/} / 1000))
}

# Clamped to what is left as well as to the call's own limit.
lock_ipc() {
  local limit=$1 remaining seconds
  shift

  remaining=$(remaining_ms)
  (( remaining > 0 )) || return 1
  (( limit < remaining )) || limit=$remaining
  printf -v seconds '%d.%03d' $((limit / 1000)) $((limit % 1000))

  timeout --kill-after=0.1s "$seconds" qs -c retro ipc call "$@"
}

# Re-requesting is idempotent, so a request that may not have landed costs
# nothing to repeat; the status poll is what confirms success.
request_lock() {
  lock_ipc "$lock_timeout_ms" lock lock >/dev/null 2>&1 || true
}

# secure: done. locking: the shell has the request and is working on it.
# Anything else, unreadable replies included, means ask again.
lock_state() {
  jq -r 'if .secure == true then "secure"
         elif .requested == true then "locking"
         else "idle" end' \
    <<<"$(lock_ipc "$status_timeout_ms" lock status 2>/dev/null)" 2>/dev/null
}

# logind suspends whether or not this wait succeeded, so a failure here
# means the machine slept with the session exposed. The notification is the
# only way anyone finds out, and it lands on the screen they unlock into.
report_unsecured() {
  printf 'retro-sleep-lock: suspending without a secure lock (%s)\n' "$1" >&2

  notify-send -u critical "Screen did not lock before suspend" \
    "The session was left unlocked ($1)." >/dev/null 2>&1 || true

  exit 1
}

request_lock

# The trailing sleep can overshoot the deadline by one interval, which is
# well inside the reserve derive_budget_ms already held back for logind.
while (( $(remaining_ms) > 0 )); do
  case $(lock_state) in
    secure) exit 0 ;;
    locking) ;;
    *) request_lock ;;
  esac

  sleep "$poll_interval"
done

report_unsecured "the shell did not secure the session within ${budget_ms}ms"
