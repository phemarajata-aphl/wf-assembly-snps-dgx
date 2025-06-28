#!/bin/bash

# Script to monitor ClonalFrameML resource usage
# Usage: ./bin/monitor_clonalframeml_resources.sh [work_directory]

WORK_DIR="${1:-$(pwd)}"
LOG_FILE="${WORK_DIR}/resource_monitor.log"

echo "ClonalFrameML Resource Monitor" | tee "$LOG_FILE"
echo "==============================" | tee -a "$LOG_FILE"
echo "Start time: $(date)" | tee -a "$LOG_FILE"
echo "Work directory: $WORK_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# System information
echo "System Information:" | tee -a "$LOG_FILE"
echo "==================" | tee -a "$LOG_FILE"
echo "Total CPUs: $(nproc)" | tee -a "$LOG_FILE"
echo "Total Memory: $(free -h | grep '^Mem:' | awk '{print $2}')" | tee -a "$LOG_FILE"
echo "Available Memory: $(free -h | grep '^Mem:' | awk '{print $7}')" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if ClonalFrameML is running
if pgrep -f "ClonalFrameML" > /dev/null; then
    echo "ClonalFrameML process found!" | tee -a "$LOG_FILE"
    
    # Get ClonalFrameML PID
    CLONAL_PID=$(pgrep -f "ClonalFrameML")
    echo "ClonalFrameML PID: $CLONAL_PID" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Monitor resources every 30 seconds
    echo "Resource Usage Monitoring:" | tee -a "$LOG_FILE"
    echo "=========================" | tee -a "$LOG_FILE"
    echo "Time | CPU% | Memory(RSS) | Memory(VSZ) | System Memory Used" | tee -a "$LOG_FILE"
    echo "-----+------+-------------+-------------+-------------------" | tee -a "$LOG_FILE"
    
    while kill -0 "$CLONAL_PID" 2>/dev/null; do
        TIMESTAMP=$(date '+%H:%M:%S')
        
        # Get process-specific stats
        if [ -f "/proc/$CLONAL_PID/stat" ]; then
            PROC_STATS=$(cat /proc/$CLONAL_PID/stat)
            CPU_PERCENT=$(ps -p "$CLONAL_PID" -o %cpu --no-headers | tr -d ' ')
            MEMORY_RSS=$(ps -p "$CLONAL_PID" -o rss --no-headers | tr -d ' ')
            MEMORY_VSZ=$(ps -p "$CLONAL_PID" -o vsz --no-headers | tr -d ' ')
            
            # Convert KB to human readable
            MEMORY_RSS_MB=$((MEMORY_RSS / 1024))
            MEMORY_VSZ_MB=$((MEMORY_VSZ / 1024))
        else
            CPU_PERCENT="N/A"
            MEMORY_RSS_MB="N/A"
            MEMORY_VSZ_MB="N/A"
        fi
        
        # Get system memory usage
        SYSTEM_MEM_USED=$(free | grep '^Mem:' | awk '{printf "%.1f%%", $3/$2 * 100.0}')
        
        printf "%s | %5s | %8s MB | %8s MB | %s\n" \
            "$TIMESTAMP" "$CPU_PERCENT" "$MEMORY_RSS_MB" "$MEMORY_VSZ_MB" "$SYSTEM_MEM_USED" | tee -a "$LOG_FILE"
        
        sleep 30
    done
    
    echo "" | tee -a "$LOG_FILE"
    echo "ClonalFrameML process completed at $(date)" | tee -a "$LOG_FILE"
    
else
    echo "ClonalFrameML process not found. Monitoring system resources..." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Monitor system resources for 10 minutes
    for i in {1..20}; do
        TIMESTAMP=$(date '+%H:%M:%S')
        SYSTEM_MEM_USED=$(free | grep '^Mem:' | awk '{printf "%.1f%%", $3/$2 * 100.0}')
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        
        echo "$TIMESTAMP | System CPU: $CPU_USAGE% | System Memory: $SYSTEM_MEM_USED" | tee -a "$LOG_FILE"
        sleep 30
    done
fi

echo "" | tee -a "$LOG_FILE"
echo "Final System State:" | tee -a "$LOG_FILE"
echo "==================" | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Monitoring completed at $(date)" | tee -a "$LOG_FILE"

# Summary
echo "" | tee -a "$LOG_FILE"
echo "Summary:" | tee -a "$LOG_FILE"
echo "========" | tee -a "$LOG_FILE"
echo "Log file saved to: $LOG_FILE" | tee -a "$LOG_FILE"

if [ -f "$LOG_FILE" ]; then
    MAX_MEM=$(grep -E "^[0-9]{2}:[0-9]{2}:[0-9]{2}" "$LOG_FILE" | awk '{print $5}' | sed 's/MB//' | sort -n | tail -1)
    if [ -n "$MAX_MEM" ] && [ "$MAX_MEM" != "N/A" ]; then
        echo "Maximum memory used by ClonalFrameML: ${MAX_MEM} MB" | tee -a "$LOG_FILE"
    fi
fi