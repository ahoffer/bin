#!/usr/bin/env bash
#
# find_history.sh — search your Bash history for a pattern
#
# Usage:
#   ./find_history.sh <pattern>
#
# The script looks for <pattern> (arg 1, required) in your Bash history file
# and prints matching commands with line numbers and color‐highlighted matches.

set -euo pipefail

# ---- argument handling ------------------------------------------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <search_pattern>" >&2
  exit 1
fi

pattern=$1

# ---- locate the history file ------------------------------------------------
histfile=${HISTFILE:-"$HOME/.bash_history"}

if [[ ! -f $histfile ]]; then
  echo "Error: history file '$histfile' not found." >&2
  exit 1
fi

# ---- search & display -------------------------------------------------------
# -F : fixed‑string search (faster, avoids unintended regex interpretation)
# -n : show line numbers
# --color=auto : highlight matches when stdout is a terminal
grep --color=auto -n -F -- "$pattern" "$histfile" || {
  # grep returns exit‑code 1 if no matches are found
  printf 'No commands in history matching: %s\n' "$pattern" >&2
}

