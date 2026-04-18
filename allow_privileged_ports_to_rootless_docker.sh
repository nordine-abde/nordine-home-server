#!/usr/bin/env bash

set -euo pipefail

# find the rootlesskit binary used by your user
which rootlesskit

# grant only the bind-to-privileged-ports capability for ports such as 21, 80, and 443
sudo setcap cap_net_bind_service=ep "$(which rootlesskit)"

# restart rootless docker (common setup)
systemctl --user restart docker
