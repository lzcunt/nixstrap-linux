#! @shell@
export PATH=@binPath@

verbose="@verbose@"

info() {
  if [[ -n "$verbose" ]]; then
    echo "$@"
  fi
}

info
info $'\e[1;32m<<< Nixstrap Linux Stage 2 (dinit) >>>\e[0m'
info

info "running udev..."
udevd --daemon
udevadm trigger --action=add
udevadm settle

cat /proc/mounts

info "starting dinit..."
exec @dinit@ -d @servicesDir@
