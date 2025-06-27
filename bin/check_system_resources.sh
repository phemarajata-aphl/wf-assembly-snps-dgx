#!/bin/bash

# System resource checker for wf-assembly-snps
# Helps diagnose memory and resource issues

echo "=== System Resource Check ==="
echo "Date: $(date)"
echo

echo "=== Memory Information ==="
echo "Total Memory:"
free -h | grep "Mem:"
echo
echo "Available Memory:"
free -h | grep "Available" || echo "Available memory info not found"
echo
echo "Memory limits:"
ulimit -v 2>/dev/null && echo "Virtual memory limit: $(ulimit -v) KB" || echo "No virtual memory limit set"
ulimit -m 2>/dev/null && echo "Physical memory limit: $(ulimit -m) KB" || echo "No physical memory limit set"
echo

echo "=== CPU Information ==="
echo "CPU cores: $(nproc)"
echo "CPU info:"
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core"
echo

echo "=== Disk Space ==="
df -h | grep -E "Filesystem|/dev/"
echo

echo "=== Current Process Limits ==="
echo "Max processes: $(ulimit -u)"
echo "Max file size: $(ulimit -f)"
echo "Max open files: $(ulimit -n)"
echo

echo "=== Docker/Singularity Memory Limits ==="
if command -v docker &> /dev/null; then
    echo "Docker memory limit:"
    docker system info 2>/dev/null | grep -i memory || echo "Docker memory info not available"
fi

if command -v singularity &> /dev/null; then
    echo "Singularity version: $(singularity --version)"
fi
echo

echo "=== Recommendations ==="
TOTAL_MEM_GB=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_MEM_GB" -lt 64 ]; then
    echo "WARNING: System has less than 64GB RAM. Consider using --skip_recombination for large datasets."
fi

if [ "$TOTAL_MEM_GB" -lt 32 ]; then
    echo "WARNING: System has less than 32GB RAM. This pipeline may fail with large datasets."
    echo "Consider running on a system with more memory or using cloud computing."
fi

echo "=== PROFILE RECOMMENDATIONS BY SYSTEM ==="
if [ "$TOTAL_MEM_GB" -ge 1400 ]; then
    echo "Google Cloud Ultra-Large VM detected: Use -profile google_vm_large"
elif [ "$TOTAL_MEM_GB" -ge 480 ] && [ "$TOTAL_MEM_GB" -le 520 ]; then
    echo "DGX Station A100 detected: Use -profile dgx_a100"
elif [ "$TOTAL_MEM_GB" -ge 128 ]; then
    echo "High-memory workstation: Use -profile large_dataset"
else
    echo "Standard system: Use -profile docker (limited to small datasets)"
fi

echo ""
echo "=== PROFILE RECOMMENDATIONS BY GENOME COUNT ==="
echo "< 50 genomes:     -profile docker"
echo "50-200 genomes:   -profile large_dataset"
echo "200-500 genomes:  -profile dgx_a100 (DGX Station) or google_vm_large (cloud)"
echo "> 500 genomes:    -profile google_vm_large"
echo

echo "=== End Resource Check ==="