#! @shell@
export PATH=@binPath@

echo "Welcome to Nixstrap Linux!";
mkdir -p /dev /proc /sys

mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys

for m in @kernelModules@; do
  modprobe "$m" || echo "modprobe $m failed"
done

while :; do
  setsid -c bash
  sleep 1
done
