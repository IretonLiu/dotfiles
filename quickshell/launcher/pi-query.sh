#!/usr/bin/env bash
set -u

if [ "$#" -lt 6 ]; then
  echo "usage: pi-query.sh <state-dir> <run-id> <model> <thinking> <system-prompt> <prompt>" >&2
  exit 64
fi

state_dir=$1
run_id=$2
model=$3
thinking=$4
system_prompt=$5
prompt=$6

mkdir -p "$state_dir"
result_file="$state_dir/pi-result"
result_tmp="$state_dir/pi-result.$run_id.tmp"
out_tmp="$state_dir/pi-output.$run_id.tmp"
err_tmp="$state_dir/pi-error.$run_id.tmp"

case "$model" in
  "gpt-5.6 luna"|"gpt-5.6-luna") model="openai-codex/gpt-5.6-luna" ;;
esac

pi_bin=${PI_BIN:-}
if [ -z "$pi_bin" ] || [ ! -x "$pi_bin" ]; then
  pi_bin=$(command -v pi 2>/dev/null || true)
fi
if [ -z "$pi_bin" ] || [ ! -x "$pi_bin" ]; then
  for fallback in "$HOME"/.local/share/pi-node/*/bin/pi; do
    if [ -x "$fallback" ]; then
      pi_bin=$fallback
      break
    fi
  done
fi

if [ -z "${pi_bin:-}" ] || [ ! -x "$pi_bin" ]; then
  : > "$out_tmp"
  printf 'pi executable not found. Set PI_BIN or ensure pi is on PATH.\n' > "$err_tmp"
  code=127
else
  args=("$pi_bin" "--print" "--thinking" "$thinking" "--no-tools" "--no-session" "--no-context-files" "--system-prompt" "$system_prompt")
  if [ "$model" != "default" ]; then
    args+=("--model" "$model")
  fi
  args+=("--" "$prompt")

  timeout_seconds=${PI_QUERY_TIMEOUT:-90}
  if timeout "$timeout_seconds" "${args[@]}" </dev/null > "$out_tmp" 2> "$err_tmp"; then
    code=0
  else
    code=$?
    if [ "$code" -eq 124 ]; then
      printf '\nTimed out after %s seconds.\n' "$timeout_seconds" >> "$err_tmp"
    fi
  fi
fi

if [ "$code" -eq 0 ]; then
  status="done"
else
  status="error"
fi

{
  printf 'RUN_ID:%s\n' "$run_id"
  printf 'STATUS:%s\n' "$status"
  printf 'CODE:%s\n' "$code"
  printf 'STDOUT:\n'
  cat "$out_tmp" 2>/dev/null || true
  printf '\n__PI_STDERR__\n'
  cat "$err_tmp" 2>/dev/null || true
} > "$result_tmp"
mv -f "$result_tmp" "$result_file"

rm -f "$out_tmp" "$err_tmp"
exit 0
