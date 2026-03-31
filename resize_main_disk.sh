#!/usr/bin/env bash

set -euo pipefail

LV_PATH="/dev/mapper/ubuntu--vg-ubuntu--lv"

echo "Warning: this will extend the main logical volume and resize the filesystem on $LV_PATH."
echo "Run this only on the intended Ubuntu host after confirming free space exists in the volume group."

if [ "${1:-}" != "--force" ]; then
  read -r -p "Continue? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 1
  fi
fi

sudo lvextend -l +100%FREE "$LV_PATH"
sudo resize2fs "$LV_PATH"

echo "Disk resize completed for $LV_PATH."
