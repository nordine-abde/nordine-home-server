#!/usr/bin/env sh

set -eu

database="${FILE_BROWSER_DATABASE:-/database/filebrowser.db}"
scan_path="${FILE_BROWSER_SHARED_SCAN_PATH:-/scans}"
grant_all_users="${FILE_BROWSER_GRANT_SCANS_TO_ALL_USERS:-true}"

case "$scan_path" in
  /*) ;;
  *)
    echo "FILE_BROWSER_SHARED_SCAN_PATH must start with /"
    exit 1
    ;;
esac

mkdir -p "/srv${scan_path}"

if [ ! -f "$database" ]; then
  echo "File Browser database does not exist yet; leaving first-run setup to File Browser."
  exit 0
fi

if ! filebrowser -d "$database" rules ls | grep -F "Allow Path:" | grep -F "$scan_path" >/dev/null 2>&1; then
  filebrowser -d "$database" rules add "$scan_path" --allow >/dev/null
fi

if [ "$grant_all_users" = "true" ]; then
  filebrowser -d "$database" users ls \
    | awk '$1 ~ /^[0-9]+$/ { print $2 }' \
    | while IFS= read -r username; do
        filebrowser -d "$database" users update "$username" --scope / >/dev/null
      done
fi
