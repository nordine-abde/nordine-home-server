#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./create_filebrowser_user.sh [--mode link|bind] [--env-file FILE] USER [SHARED_PATH[:FOLDER]...]

Creates or updates a File Browser user scoped to /home/USER, creates that home
directory under FILE_BROWSER_SRV_FOLDER, and attaches shared folders inside it.

SHARED_PATH values are File Browser paths under /srv, for example:
  /scans
  /scans:Scans
  /documents:Documents

Password handling:
  - Existing users keep their current password.
  - New users use FILE_BROWSER_NEW_USER_PASSWORD when set, otherwise the script
    prompts for a password.

Modes:
  link  Create relative symlinks. This is simple and does not require sudo.
  bind  Run mount --bind from the host. This may require sudo and is not
        persistent across reboot unless also configured in /etc/fstab or a
        systemd mount unit.
EOF
}

mode="link"
env_file=".env"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --env-file)
      env_file="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -lt 1 ]; then
  usage >&2
  exit 1
fi

case "$mode" in
  link|bind) ;;
  *)
    echo "--mode must be either link or bind" >&2
    exit 1
    ;;
esac

username="$1"
shift

case "$username" in
  ""|.|..|*/*)
    echo "USER must be a simple File Browser username, not a path" >&2
    exit 1
    ;;
esac

if ! [[ "$username" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "USER may only contain letters, numbers, dots, underscores, and hyphens" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if [ ! -f "$env_file" ]; then
  echo "Environment file not found: $env_file" >&2
  exit 1
fi

env_file_abs="$(realpath "$env_file")"

set -a
# shellcheck disable=SC1090
. "$env_file_abs"
set +a

srv_folder="${FILE_BROWSER_SRV_FOLDER:-./data/filebrowser/srv}"
if [[ "$srv_folder" = /* ]]; then
  srv_root="$srv_folder"
else
  srv_root="$repo_root/$srv_folder"
fi
srv_root="$(realpath -m "$srv_root")"

database_folder="${FILE_BROWSER_DATABASE_FOLDER:-./data/filebrowser/database}"
if [[ "$database_folder" = /* ]]; then
  database_root="$database_folder"
else
  database_root="$repo_root/$database_folder"
fi
database_root="$(realpath -m "$database_root")"

home_path="/home/$username"
home_dir="$srv_root${home_path}"

mkdir -p "$home_dir" "$database_root"

fb() {
  docker compose --env-file "$env_file_abs" run --rm --no-deps filebrowser \
    -d /database/filebrowser.db "$@"
}

if [ ! -f "$database_root/filebrowser.db" ]; then
  fb config init --root /srv --createUserDir >/dev/null
else
  fb config set --root /srv --createUserDir >/dev/null
fi

user_exists() {
  fb users ls | awk -v name="$username" '$1 ~ /^[0-9]+$/ && $2 == name { found = 1 } END { exit found ? 0 : 1 }'
}

if user_exists; then
  fb users update "$username" --scope "$home_path" >/dev/null
  echo "Updated File Browser user '$username' with scope $home_path."
else
  password="${FILE_BROWSER_NEW_USER_PASSWORD:-}"
  if [ -z "$password" ]; then
    if [ ! -t 0 ]; then
      echo "Set FILE_BROWSER_NEW_USER_PASSWORD when running non-interactively." >&2
      exit 1
    fi

    read -r -s -p "Password for new File Browser user '$username': " password
    echo
    read -r -s -p "Repeat password: " password_repeat
    echo

    if [ "$password" != "$password_repeat" ]; then
      echo "Passwords do not match." >&2
      exit 1
    fi
  fi

  fb users add "$username" "$password" --scope "$home_path" >/dev/null
  echo "Created File Browser user '$username' with scope $home_path."
fi

attach_shared_path() {
  shared_spec="$1"
  shared_path="${shared_spec%%:*}"
  folder_name="${shared_spec#*:}"

  if [ "$folder_name" = "$shared_spec" ]; then
    folder_name="$(basename "$shared_path")"
  fi

  case "$shared_path" in
    /*) ;;
    *)
      echo "Shared path must start with /: $shared_path" >&2
      exit 1
      ;;
  esac

  case "$folder_name" in
    ""|.|..|*/*)
      echo "Folder alias must be a simple folder name: $folder_name" >&2
      exit 1
      ;;
  esac

  source_dir="$srv_root${shared_path}"
  target_dir="$home_dir/$folder_name"

  mkdir -p "$source_dir"

  case "$mode" in
    link)
      if [ -e "$target_dir" ] && [ ! -L "$target_dir" ]; then
        echo "Refusing to replace existing non-symlink: $target_dir" >&2
        exit 1
      fi

      relative_source="$(realpath --relative-to="$home_dir" "$source_dir")"
      ln -sfn "$relative_source" "$target_dir"
      echo "Linked $home_path/$folder_name -> $shared_path."
      ;;
    bind)
      mkdir -p "$target_dir"
      if mountpoint -q "$target_dir"; then
        echo "Bind mount already exists: $target_dir."
      else
        sudo mount --bind "$source_dir" "$target_dir"
        echo "Bind mounted $shared_path at $home_path/$folder_name."
      fi
      ;;
  esac
}

for shared_spec in "$@"; do
  attach_shared_path "$shared_spec"
done
