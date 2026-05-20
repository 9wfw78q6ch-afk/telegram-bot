#!/bin/zsh
set -euo pipefail

cd /Users/mikolassvatos/Desktop/Bez\ názvu

if [[ -f .venv/bin/activate ]]; then
  source .venv/bin/activate
fi

python aidailybrief_watch.py >> automation.log 2>&1
