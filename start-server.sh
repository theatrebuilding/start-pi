#!/bin/bash
set -euo pipefail

# Constants – adjust these as needed
BRANCH_NAME="experimental"           # Branch name to sync with
TARGET_DIR="fiveminutesago/production/2_server"
PYTHON_SCRIPT="server.py"        # Name of the python script to run

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

# 5. Execute the python command (without additional flags)
PYTHON_CMD=(python3 "$PYTHON_SCRIPT")
echo "Executing: ${PYTHON_CMD[*]}"
if ! "${PYTHON_CMD[@]}"; then
  echo "Error: Python command failed"
  exit 1
fi

echo "Script completed successfully."
