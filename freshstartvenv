#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

VENV_DIR="$HOME/.venv/default"

# ─── Create the virtualenv if it doesn't exist ───
if [[ ! -d "$VENV_DIR" ]]; then
  echo "📂 Creating venv at $VENV_DIR"
  mkdir -p "${VENV_DIR%/*}"
  python3 -m venv "$VENV_DIR"
else
  echo "✅ Virtualenv already exists at $VENV_DIR"
fi

# ─── Activate and install your YAML formatter ───
echo "🚀 Activating venv and installing yamlfix…"
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install yamlfix

echo
echo "🎉 All set! To use it:"
echo "    source \"$VENV_DIR/bin/activate\""
echo "    yamlfix --help"

