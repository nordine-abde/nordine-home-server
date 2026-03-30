#!/usr/bin/env bash

set -e

# Check if email argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <email>"
  exit 1
fi

EMAIL="$1"

# Run ssh-keygen without specifying -f (interactive path selection)
ssh-keygen -t ed25519 -C "$EMAIL"

echo "SSH key generation completed."
