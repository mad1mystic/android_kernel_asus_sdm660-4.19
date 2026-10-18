#!/usr/bin/env bash
# Fail the build if the shipped DTB does not carry the proven camera overlay.
#
# History: the X00TD camera sensor overlay
#   arch/arm64/boot/dts/vendor/qcom/X00TD/sdm630-camera-sensor-qrd-overlay.dtsi
# was rewritten in-tree (custom regulators on gpio51, extra pinctrl, re-added
# actuator/eeprom wiring). The rewrite left NOT A SINGLE physical camera
# sensor probing: the whole camera subsystem registered fine (cci, csiphy,
# csid, vfe, cpp, jpeg -> /sys/class/video4linux full of subdevs) but there
# were zero msm_sensor devices, so the camera provider (Lineage's
# provider-service_32 + mm-camera shim) enumerated zero cameras and exited
# with status 1 every ~5 s in an init restart loop. The camera was dead on
# every build that shipped the rewrite (this is also why rsuntk/rskseven
# builds had no camera).
#
# The fix was to take LineageOS' (lineage-24.0) version of that overlay
# verbatim. This gate asserts the BUILT dtb has that exact shape:
#   positive: 3 cameras, 2 eeproms, flash/subflash nodes, sensor gpio tables,
#             front camera on csiphy-sd 2;
#   negative: the nodes the overlay deletes from the QRD base are gone, the
#             custom gpio51 regulator is gone, the actuator lost its vreg
#             wiring -- each of which can only hold if the overlay really
#             applied on top of the base (a silently dropped include would
#             leave the old/base shape and fail here).
# It decompiles with the kernel's own scripts/dtc/dtc (built during the
# kernel build, so it is always present at this point), and additionally
# greps the BYTES THAT SHIP (Image.gz-dtb) for the same markers.
#
# Usage: check_camera_dtb.sh <path/to/Image.gz-dtb>   (run from ksrc/)
set -euo pipefail

IMG="${1:?usage: check_camera_dtb.sh <Image.gz-dtb>}"
DTB="out/arch/arm64/boot/dts/vendor/qcom/sdm636-qrd-X00TD.dtb"
DTS_OUT="${TMPDIR:-.}/x00td-camera-gate.dts"

fail=0
err() { echo "::error::check_camera_dtb: $*"; fail=1; }

[ -s "$DTB" ] || { echo "::error::check_camera_dtb: no X00TD dtb at $DTB"; exit 1; }
[ -s "$IMG" ]  || { echo "::error::check_camera_dtb: missing $IMG"; exit 1; }

DTC=""
for c in scripts/dtc/dtc /usr/bin/dtc /usr/local/bin/dtc; do
  [ -x "$c" ] && DTC="$c" && break
done
[ -n "$DTC" ] || { echo "::error::check_camera_dtb: dtc not found (scripts/dtc/dtc must exist after the kernel build)"; exit 1; }

"$DTC" -I dtb -O dts -o "$DTS_OUT" "$DTB" 2>"$DTS_OUT.err" || {
  cat "$DTS_OUT.err"; echo "::error::check_camera_dtb: dtc failed to decompile $DTB"; exit 1; }
echo "check_camera_dtb: decompiled $DTB ($(wc -l < "$DTS_OUT") lines of dts)"

# Print the first balanced {...} block whose opening line contains $1.
block() {
  awk -v pat="$1" '
    !f && index($0, pat) { f=1; start=NR }
    f {
      print
      line=$0; o=gsub(/{/,"{",line); line=$0; c=gsub(/}/,"}",line)
      d += o - c
      if (d==0 && NR>start) exit
    }' "$DTS_OUT"
}

# --- positive assertions: the proven shape must be there -------------------
for n in qcom,camera@0 qcom,camera@1 qcom,camera@2 qcom,eeprom@0 qcom,eeprom@1 \
         qcom,camera-flash@0 qcom,camera-subflash@1; do
  grep -qF "$n" "$DTS_OUT" || err "MISSING node $n"
done

# --- negative assertions: only hold if the overlay really applied ----------
for n in qcom,eeprom@2 qcom,ois@0 qcom,actuator@1 cam_avdd_gpio_regulator \
         cam_vaf_fixed_regulator cam_rear_dvdd_fixed_regulator; do
  grep -qF "$n" "$DTS_OUT" && err "UNEXPECTED $n (broken/base overlay state)"
done

# front camera must sit on csiphy-sd 2 (the overlay's explicit assignment)
grep -A6 -F 'qcom,camera@1 {' "$DTS_OUT" | grep -qF 'qcom,csiphy-sd-index = <0x2>' \
  || err "camera@1 qcom,csiphy-sd-index is not <0x2>"

# the overlay strips the actuator's vreg wiring; still present => not applied
if block 'qcom,actuator@0 {' | grep -qF 'qcom,cam-vreg-name'; then
  err "qcom,actuator@0 still carries qcom,cam-vreg-name (overlay not applied)"
fi

# rear/depth keep their reset+MCLK gpio tables (base camera nodes intact)
for cam in 'qcom,camera@0 {' 'qcom,camera@2 {'; do
  block "$cam" | grep -qF 'qcom,gpio-req-tbl-num' || err "$cam lost qcom,gpio-req-tbl-num"
done

# --- the bytes that actually ship must agree -------------------------------
grep -aqF 'qcom,camera@2' "$IMG" || err "shipped Image.gz-dtb has no qcom,camera@2 node"
grep -aqF 'cam_avdd_gpio_regulator' "$IMG" \
  && err "shipped Image.gz-dtb still contains the broken cam_avdd_gpio_regulator marker"

if [ "$fail" -ne 0 ]; then
  echo "check_camera_dtb: FAILED - this build would ship a dead camera"
  exit 1
fi
echo "check_camera_dtb: OK - LineageOS-proven camera sensor overlay is in the shipped DTB"
