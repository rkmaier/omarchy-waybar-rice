#!/bin/bash

# Read GPU usage for AMD GPU (card1 - discrete GPU)
GPU_USAGE=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo "0")

# Output the usage percentage
echo "${GPU_USAGE}%"
