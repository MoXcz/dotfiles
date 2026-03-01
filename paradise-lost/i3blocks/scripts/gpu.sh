#!/usr/bin/env bash

GPU_USAGE=$(/usr/bin/nvidia-smi \
  --query-gpu=utilization.gpu \
  --format=csv,noheader,nounits 2>/dev/null)

GPU_TEMP=$(/usr/bin/nvidia-smi \
  --query-gpu=temperature.gpu \
  --format=csv,noheader,nounits 2>/dev/null)

[ -z "$GPU_USAGE" ] && GPU_USAGE="N/A"
[ -z "$GPU_TEMP" ] && GPU_TEMP="N/A"

echo "GPU: ${GPU_USAGE}% at ${GPU_TEMP} C"

