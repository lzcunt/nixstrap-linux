#! @shell@
export PATH=@binPath@

verbose="@verbose@"

info() {
  if [[ -n "$verbose" ]]; then
    echo "$@"
  fi
}

info
info $'\e[1;32m<<< Nixstrap Linux Stage 1 >>>\e[0m'
info

mkdir -p /dev /proc /sys /run

mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys

for m in @kernelModules@; do
  info "loading module $m"
  modprobe "$m" || echo "modprobe $m failed"
done

ln -sfn /proc/self/fd /dev/fd
ln -sfn /proc/self/fd/0 /dev/stdin
ln -sfn /proc/self/fd/1 /dev/stdout
ln -sfn /proc/self/fd/2 /dev/stderr

info "running udev..."
udevd --daemon
udevadm trigger --action=add
udevadm settle

while :; do
  setsid -c bash
  sleep 1
done
