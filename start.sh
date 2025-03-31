#!/bin/bash
set -euo pipefail

# Constants – adjust these as needed
BRANCH_NAME="experimental"           # Branch name to sync with
DEVICE_NAME="Scarlett 8i6 USB" # Device we are looking for
COUNTRY="dk"                   # Country parameter for the python command
TARGET_DIR="fiveminutesago/production/1_sender"
PYTHON_SCRIPT="send.py"        # Name of the python script to run

# 1. Change directory to the project folder
if ! cd "$TARGET_DIR"; then
  echo "Error: Could not change directory to $TARGET_DIR"
  exit 1
fi

# 2. Fetch the latest changes from remote
if ! git fetch origin; then
  echo "Error: Git fetch failed"
  exit 1
fi

# 3. Hard reset the local branch to match remote branch defined in BRANCH_NAME
if ! git reset --hard origin/"$BRANCH_NAME"; then
  echo "Error: Git reset failed"
  exit 1
fi

# Optionally, clean untracked files and directories:
if ! git clean -fd; then
  echo "Error: Git clean failed"
  exit 1
fi

# 4. (Optional) Pull latest changes (should be redundant after reset)
if ! git pull; then
  echo "Error: Git pull failed"
  exit 1
fi

# 5. List audio capture devices and extract the card and device numbers
DEVICE_LINE=$(arecord -l | grep "$DEVICE_NAME" || true)
if [[ -z "$DEVICE_LINE" ]]; then
  echo "Error: Device '$DEVICE_NAME' not found in arecord output."
  exit 1
fi

# Extract the card and device numbers using sed
CARD_NUMBER=$(echo "$DEVICE_LINE" | sed -n 's/.*card \([0-9]\+\):.*/\1/p')
DEVICE_NUMBER=$(echo "$DEVICE_LINE" | sed -n 's/.*device \([0-9]\+\):.*/\1/p')

if [[ -z "$CARD_NUMBER" || -z "$DEVICE_NUMBER" ]]; then
  echo "Error: Could not parse card/device numbers from: $DEVICE_LINE"
  exit 1
fi

# 6. Execute the python command with the extracted parameters
PYTHON_CMD=(python3 "$PYTHON_SCRIPT" --device "plughw:${CARD_NUMBER},${DEVICE_NUMBER}" --country "$COUNTRY")
echo "Executing: ${PYTHON_CMD[*]}"
if ! "${PYTHON_CMD[@]}"; then
  echo "Error: Python command failed"
  exit 1
fi

echo "Script completed successfully."
