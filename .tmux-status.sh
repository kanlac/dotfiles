#!/bin/zsh

# CPU
logical=$(sysctl -n hw.logicalcpu)
cpu=$(ps -A -o %cpu= | awk -v n="$logical" '{s+=$1} END {printf "%.0f%%", s/n}')

# Memory
total_bytes=$(sysctl -n hw.memsize)
free_pct=$(memory_pressure | awk -F': *' '/System-wide memory free percentage/ {gsub(/%/,"",$2); print $2}')
mem=$(awk -v t="$total_bytes" -v f="$free_pct" 'BEGIN{
  tGB=t/1024/1024/1024
  uPct=100-f
  uGB=tGB*uPct/100
  printf "%.1fG(%d%%)", uGB, uPct
}')

echo "cpu:$cpu mem:$mem"
