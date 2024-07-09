#!/usr/bin/env bash
# set -euo pipefail

_edit_config() {
  local FILE_TO_OPEN="$1"
  local FILE_TITLE="$2"

  local FILE_NAME=$(basename $FILE_TO_OPEN)
  local CURRENT_COMMAND=$(basename $0)

  if [ "$1" = "--help" ]; then
      echo "Open $FILE_TITLE in the preferred text editor"
      echo "Usage:"
      echo "  :config:$CURRENT_COMMAND"
      echo "Examples:"
      echo "  :config:$CURRENT_COMMAND"
      return 0
  fi

  # Check if the file exists
  if [ ! -f "$FILE_TO_OPEN" ]; then
    echo "The $FILE_TO_OPEN file cannot be found"
    return 1
  fi

  sudo "$LETDEV_HOME/commands/:/edit" "$FILE_TO_OPEN"
}
