#!/usr/bin/env sh

set -eu

database="${FILE_BROWSER_DATABASE:-/database/filebrowser.db}"
admin_password="${FILE_BROWSER_ADMIN_PASSWORD:-}"
users="${FILE_BROWSER_BOOTSTRAP_USERS:-}"
shared_folders="${FILE_BROWSER_BOOTSTRAP_SHARED_FOLDERS:-/scans:Scans}"
minimum_password_length="${FILE_BROWSER_MINIMUM_PASSWORD_LENGTH:-12}"
database_available=false

validate_simple_name() {
  value="$1"
  label="$2"

  case "$value" in
    ""|.|..|*/*)
      echo "$label must be a simple name: $value" >&2
      exit 1
      ;;
  esac

  if ! echo "$value" | grep -Eq '^[A-Za-z0-9._-]+$'; then
    echo "$label may only contain letters, numbers, dots, underscores, and hyphens: $value" >&2
    exit 1
  fi
}

validate_shared_path() {
  shared_path="$1"

  case "$shared_path" in
    /*) ;;
    *)
      echo "Shared folder path must start with /: $shared_path" >&2
      exit 1
      ;;
  esac

  case "$shared_path" in
    *"/../"*|*"/.."|".."*|"."|"/.")
      echo "Shared folder path must not contain path traversal: $shared_path" >&2
      exit 1
      ;;
  esac
}

validate_minimum_password_length() {
  case "$minimum_password_length" in
    ""|*[!0-9]*)
      echo "FILE_BROWSER_MINIMUM_PASSWORD_LENGTH must be a non-negative integer." >&2
      exit 1
      ;;
  esac
}

user_exists() {
  username="$1"

  filebrowser -d "$database" users ls \
    | awk -v name="$username" '$1 ~ /^[0-9]+$/ && $2 == name { found = 1 } END { exit found ? 0 : 1 }'
}

ensure_filebrowser_config() {
  validate_minimum_password_length

  if [ ! -f "$database" ]; then
    if [ -n "$admin_password" ] || [ -n "$users" ]; then
      filebrowser -d "$database" config init \
        --root /srv \
        --createUserDir \
        --minimumPasswordLength "$minimum_password_length" >/dev/null
      database_available=true
    else
      echo "File Browser database does not exist and no File Browser users are configured."
      echo "Leaving first-run database setup to File Browser."
    fi
  else
    filebrowser -d "$database" config set \
      --root /srv \
      --createUserDir \
      --minimumPasswordLength "$minimum_password_length" >/dev/null
    database_available=true
  fi
}

ensure_admin_user() {
  if [ -z "$admin_password" ]; then
    return
  fi

  if [ "$database_available" != "true" ]; then
    echo "Cannot configure admin user without a File Browser database." >&2
    exit 1
  fi

  if user_exists "admin"; then
    filebrowser -d "$database" users update \
      admin \
      --password "$admin_password" \
      --scope / \
      --perm.admin >/dev/null
    echo "Updated File Browser admin user."
  else
    filebrowser -d "$database" users add \
      admin \
      "$admin_password" \
      --scope / \
      --perm.admin >/dev/null
    echo "Created File Browser admin user."
  fi
}

ensure_shared_folder() {
  shared_spec="$1"
  shared_path="${shared_spec%%:*}"

  validate_shared_path "$shared_path"
  mkdir -p "/srv${shared_path}"

  if [ "$database_available" != "true" ]; then
    return
  fi

  if ! filebrowser -d "$database" rules ls | grep -F "Allow Path:" | grep -F "$shared_path" >/dev/null 2>&1; then
    filebrowser -d "$database" rules add "$shared_path" --allow >/dev/null
  fi
}

attach_shared_folder() {
  username="$1"
  shared_spec="$2"
  shared_path="${shared_spec%%:*}"
  folder_name="${shared_spec#*:}"

  if [ "$folder_name" = "$shared_spec" ]; then
    folder_name="$(basename "$shared_path")"
  fi

  validate_shared_path "$shared_path"
  validate_simple_name "$folder_name" "Shared folder alias"

  home_dir="/srv/home/$username"
  target_path="$home_dir/$folder_name"
  relative_source="../../${shared_path#/}"

  mkdir -p "$home_dir" "/srv${shared_path}"

  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    echo "Refusing to replace existing non-symlink: $target_path" >&2
    exit 1
  fi

  ln -sfn "$relative_source" "$target_path"
}

ensure_user() {
  user_spec="$1"
  username="${user_spec%%:*}"
  password="${user_spec#*:}"
  home_path="/home/$username"

  validate_simple_name "$username" "File Browser username"
  mkdir -p "/srv${home_path}"

  if user_exists "$username"; then
    filebrowser -d "$database" users update "$username" --scope "$home_path" >/dev/null
    echo "Updated File Browser user '$username' with scope $home_path."
  else
    if [ "$password" = "$user_spec" ] || [ -z "$password" ]; then
      echo "Missing password for new File Browser user '$username'." >&2
      echo "Use FILE_BROWSER_BOOTSTRAP_USERS='$username:password'." >&2
      exit 1
    fi

    filebrowser -d "$database" users add "$username" "$password" --scope "$home_path" >/dev/null
    echo "Created File Browser user '$username' with scope $home_path."
  fi

  if [ -n "$shared_folders" ]; then
    echo "$shared_folders" | tr ',' '\n' | while IFS= read -r shared_spec; do
      [ -n "$shared_spec" ] || continue
      attach_shared_folder "$username" "$shared_spec"
    done
  fi
}

ensure_filebrowser_config
ensure_admin_user

if [ -n "$shared_folders" ]; then
  echo "$shared_folders" | tr ',' '\n' | while IFS= read -r shared_spec; do
    [ -n "$shared_spec" ] || continue
    ensure_shared_folder "$shared_spec"
  done
fi

if [ -n "$users" ]; then
  echo "$users" | tr ',' '\n' | while IFS= read -r user_spec; do
    [ -n "$user_spec" ] || continue
    ensure_user "$user_spec"
  done
else
  echo "No FILE_BROWSER_BOOTSTRAP_USERS configured; shared folders were still prepared."
fi
