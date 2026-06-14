#!/usr/bin/env bash
# Runs tests that are seen by both the server and the client while the client is connected.
#
# HeadlessNH parks the client at the serverloaded gate right after it joins, so
# for the length of this script the connection should live and we can poke it from
# both ends: the server (over RCON) and the client (xdotool, but probably not needed for now).
#
# The orchestrator should emit the gate once this one has run to release the client again.
# 
# A result should be verified later (like in other scripts)
set -uo pipefail
shopt -s nullglob

RUN_DIR="${RUN_DIR:?RUN_DIR must be set}"
CLIENT_MC_DIR="${CLIENT_MC_DIR:?CLIENT_MC_DIR must be set}"

RCON_HOST="${RCON_HOST:-localhost}"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:?RCON_PASSWORD must be set}"

# Capture whatever each side emits for the length of this script (-n 0: new lines only)
tail -n 0 -F "$RUN_DIR/server.log" > "$RUN_DIR/dual_test_server.log" 2>/dev/null &
server_tail_pid=$!
tail -n 0 -F "$RUN_DIR/client.log" > "$RUN_DIR/dual_test_client.log" 2>/dev/null &
client_tail_pid=$!
trap 'kill "$server_tail_pid" "$client_tail_pid" 2>/dev/null' EXIT

rc=0

# Ask the server who's online
players_line=$(rcon-cli --host "$RCON_HOST" --port "$RCON_PORT" --password "$RCON_PASSWORD" list 2>&1)
echo "server 'list' -> $players_line"
online=$(printf '%s' "$players_line" | grep -oiE 'there are [0-9]+' | grep -oE '[0-9]+' | head -1)
if [ -n "$online" ] && [ "$online" -ge 1 ]; then
  echo "server reports $online player(s) online"
else
  echo "server sees no players -- client not visible from the server side?"
  rc=1
fi

crash_reports=("$CLIENT_MC_DIR/crash-reports/crash"*.txt)
if [ "${#crash_reports[@]}" -gt 0 ]; then
  echo "discovered new client crash report while connected: ${crash_reports[-1]##*/}"
  rc=1
fi

# Let the log lines each side emitted in reaction settle into the tails
sleep 2

# TODO: Wait for HQA report file to appear here

echo "$rc" > "$DUAL_EXIT_FLAG"
[ "$rc" -eq 0 ] && echo "DUAL: pass" || echo "DUAL: fail"
exit "$rc"
