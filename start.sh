#!/bin/bash
# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error and propagate errors in pipelines.
set -euo pipefail

MOUNT_POINT="/mnt/tbdrive"
DEVICE="/dev/sda1"

# Ensure that the mount point directory exists.
if [ ! -d "$MOUNT_POINT" ]; then
  echo "Directory $MOUNT_POINT does not exist, creating it..."
  sudo mkdir -p "$MOUNT_POINT"
fi

# Check if the mount point is already in use.
if ! mountpoint -q "$MOUNT_POINT"; then
  echo "$MOUNT_POINT is not mounted. Mounting $DEVICE on $MOUNT_POINT..."
  sudo mount "$DEVICE" "$MOUNT_POINT"
else
  echo "$MOUNT_POINT is already mounted."
  # Get the current mount options for the device.
  MOUNT_INFO=$(grep "$MOUNT_POINT" /proc/mounts)
  echo "Current mount info: $MOUNT_INFO"
  
  # Check if the mount is read-only.
  if echo "$MOUNT_INFO" | grep -q "ro,"; then
    echo "$MOUNT_POINT is mounted as read-only. Remounting as read-write..."
    sudo mount -o remount,rw "$DEVICE" "$MOUNT_POINT"
  fi
fi

# Verify that the mount is now read-write.
if grep "$MOUNT_POINT" /proc/mounts | grep -q "rw,"; then
  echo "$MOUNT_POINT is now mounted with read-write permissions."
else
  echo "Error: $MOUNT_POINT is not mounted read-write." 1>&2
  exit 1
fi

# Constants – adjust these as needed
BRANCH_NAME="onepi-dsp"           # Branch name to sync with
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

