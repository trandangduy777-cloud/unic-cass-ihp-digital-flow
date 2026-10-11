#!/bin/bash
# Chay LibreLane cho tung khoi (trong container cua khoa UNIC-CASS) va in so lieu chinh.
# Dung: ./run_flow.sh            (chay ca 5)    ./run_flow.sh pwm   (chay 1 khoi)
cd "$(dirname "$0")"
list=${1:-"spi i2c fifo pwm vga"}
for d in $list; do
  echo "===== $d ====="
  (cd $d && librelane --pdk-root /opt/pdks --manual-pdk --pdk ihp-sg13g2 --run-tag run1 config.yaml \
   && grep -E 'design__instance_count"|design__instance_area"|timing__setup_ws|timing__hold_ws' runs/run1/final/metrics.json)
done
