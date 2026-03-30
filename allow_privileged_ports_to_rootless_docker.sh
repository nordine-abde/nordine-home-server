# find the rootlesskit binary used by your user
which rootlesskit

# grant only the bind-to-privileged-ports capability
sudo setcap cap_net_bind_service=ep "$(which rootlesskit)"

# restart rootless docker (common setup)
systemctl --user restart docker
