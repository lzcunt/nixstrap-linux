#! @shell@
export PATH=@binPath@

verbose="@verbose@"
targetRoot=/mnt
console=tty1

info() {
  if [[ -n "$verbose" ]]; then
    echo "$@"
  fi
}

fail() {
  cat <<EOF

An error occurred in stage 1 of the boot process, which must mount the
root filesystem on \`$targetRoot' and then start stage 2. Press any key
to start an interactive shell.
EOF

  read -n 1 reply

  runShell
}

runShell() {
  while :; do
    setsid -c -w @shell@ -c "exec @shell@ < /dev/$console >/dev/$console 2>/dev/$console"
    sleep 1
  done
}

trap 'fail' 0

info
info $'\e[1;32m<<< Nixstrap Linux Stage 1 >>>\e[0m'
info

mkdir -p /dev /proc /sys /run /mnt

mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t tmpfs -o mode=0755 tmpfs /run

stage2Init=/init
for o in $(cat /proc/cmdline); do
  case $o in
    console=*)
      console=${o#console=}
      console=${console%%,*}
      ;;
    init=*)
      stage2Init=${o#init=}
      ;;
  esac
done

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

switchRoot=$(type -P switch_root)
if [[ -z "$switchRoot" ]]; then
  info "switch_root not found"
  fail
fi

info "mounting new root..."
mount -t tmpfs -o mode=0755 tmpfs $targetRoot || fail
mkdir -p $targetRoot/iso $targetRoot/nix/.ro-store $targetRoot/nix/.rw-store $targetRoot/nix/store
mkdir -m 0755 -p $targetRoot/proc $targetRoot/sys $targetRoot/dev $targetRoot/run

if [[ -e /dev/sr0 ]]; then
  info "mounting cdrom..."
  mount -t iso9660 -o ro /dev/sr0 $targetRoot/iso || fail
else
  info "failed to find cdrom"
  fail
fi

if [[ -e $targetRoot/iso/nix-store.squashfs ]]; then
  info "mounting nix-store.squashfs..."
  mount -t squashfs -o loop,ro $targetRoot/iso/nix-store.squashfs $targetRoot/nix/.ro-store || fail
else
  info "failed to find nix-store.squashfs"
  fail
fi

info "mounting writable store overlay..."
mount -t tmpfs -o mode=0755 tmpfs $targetRoot/nix/.rw-store || fail
mkdir -m 0700 -p $targetRoot/nix/.rw-store/store $targetRoot/nix/.rw-store/work
mount -t overlay overlay \
  -o "lowerdir=$targetRoot/nix/.ro-store,upperdir=$targetRoot/nix/.rw-store/store,workdir=$targetRoot/nix/.rw-store/work" \
  $targetRoot/nix/store || fail

info "copying udev support files..."
mkdir -p $targetRoot/etc/udev
cp -rL /etc/udev/rules.d $targetRoot/etc/udev/
ln -sfn "$(readlink -f /lib)" $targetRoot/lib
mkdir -p $targetRoot/sbin
ln -sfn "$(type -P modprobe)" $targetRoot/sbin/modprobe

info "stopping udev..."
udevadm control --exit

if [[ ! -e "$targetRoot/$stage2Init" ]]; then
  info "stage 2 init script ($targetRoot/$stage2Init) not found"
  fail
fi

info "switching root..."
mount --move /proc $targetRoot/proc || fail
mount --move /sys $targetRoot/sys || fail
mount --move /run $targetRoot/run || fail
mount --move /dev $targetRoot/dev || fail

exec env -i "$switchRoot" "$targetRoot" "$stage2Init"
