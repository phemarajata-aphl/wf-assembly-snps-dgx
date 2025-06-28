#!/bin/bash

# Script to monitor Gubbins performance and memory usage
# Usage: ./bin/monitor_gubbins_performance.sh [work_directory]

WORK_DIR="${1:-work}"
LOG_FILE="${WORK_DIR}/gubbins_performance.log"

echo "Gubbins Performance Monitor" | tee "$LOG_FILE"
echo "===========================" | tee -a "$LOG_FILE"
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

# Check if Gubbins is running
if pgrep -f "run_gubbins.py\|gubbins" > /dev/null; then
    echo "Gubbins process found!" | tee -a "$LOG_FILE"
    
    # Get Gubbins PID
    GUBBINS_PID=$(pgrep -f "run_gubbins.py\|gubbins" | head -1)
    echo "Gubbins PID: $GUBBINS_PID" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Monitor resources every 60 seconds
    echo "Resource Usage Monitoring (every 60 seconds):" | tee -a "$LOG_FILE"
    echo "=============================================" | tee -a "$LOG_FILE"
    echo "Time | CPU% | Memory(RSS) | Memory(VSZ) | System Memory Used | Gubbins Stage" | tee -a "$LOG_FILE"
    echo "-----+------+-------------+-------------+-------------------+--------------" | tee -a "$LOG_FILE"
    
    ITERATION_COUNT=0
    while kill -0 "$GUBBINS_PID" 2>/dev/null; do
        TIMESTAMP=$(date '+%H:%M:%S')
        
        # Get process-specific stats
        if [ -f "/proc/$GUBBINS_PID/stat" ]; then
            CPU_PERCENT=$(ps -p "$GUBBINS_PID" -o %cpu --no-headers | tr -d ' ')
            MEMORY_RSS=$(ps -p "$GUBBINS_PID" -o rss --no-headers | tr -d ' ')
            MEMORY_VSZ=$(ps -p "$GUBBINS_PID" -o vsz --no-headers | tr -d ' ')
            
            # Convert KB to human readable
            MEMORY_RSS_GB=$((MEMORY_RSS / 1024 / 1024))
            MEMORY_VSZ_GB=$((MEMORY_VSZ / 1024 / 1024))
        else
            CPU_PERCENT="N/A"
            MEMORY_RSS_GB="N/A"
            MEMORY_VSZ_GB="N/A"
        fi
        
        # Get system memory usage
        SYSTEM_MEM_USED=$(free | grep '^Mem:' | awk '{printf "%.1f%%", $3/$2 * 100.0}')
        
        # Try to determine Gubbins stage from log files
        GUBBINS_STAGE="Unknown"
        if [ -d "$WORK_DIR" ]; then
            # Look for recent Gubbins log messages
            RECENT_LOG=$(find "$WORK_DIR" -name ".command.out" -exec grep -l "gubbins\|Gubbins" {} \; 2>/dev/null | head -1)
            if [ -n "$RECENT_LOG" ]; then
                if tail -20 "$RECENT_LOG" | grep -q "Reconstructing ancestral sequences"; then
                    GUBBINS_STAGE="Ancestral_Seq"
                elif tail -20 "$RECENT_LOG" | grep -q "Building tree"; then
                    GUBBINS_STAGE="Tree_Building"
                elif tail -20 "$RECENT_LOG" | grep -q "Iteration"; then
                    ITER_NUM=$(tail -20 "$RECENT_LOG" | grep "Iteration" | tail -1 | grep -o "Iteration [0-9]*" | grep -o "[0-9]*")
                    GUBBINS_STAGE="Iter_$ITER_NUM"
                elif tail -20 "$RECENT_LOG" | grep -q "Finding recombination"; then
                    GUBBINS_STAGE="Find_Recomb"
                fi
            fi
        fi
        
        printf "%s | %5s | %8s GB | %8s GB | %s | %s\n" \
            "$TIMESTAMP" "$CPU_PERCENT" "$MEMORY_RSS_GB" "$MEMORY_VSZ_GB" "$SYSTEM_MEM_USED" "$GUBBINS_STAGE" | tee -a "$LOG_FILE"
        
        # Every 10 iterations (10 minutes), show more detailed info
        if [ $((ITERATION_COUNT % 10)) -eq 0 ]; then
            echo "" | tee -a "$LOG_FILE"
            echo "Detailed system status at $(date):" | tee -a "$LOG_FILE"
            echo "Memory breakdown:" | tee -a "$LOG_FILE"
            free -h | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Check for any error messages in recent logs
            if [ -n "$RECENT_LOG" ]; then
                ERROR_MSGS=$(tail -50 "$RECENT_LOG" | grep -i "error\|fail\|exception" | tail -3)
                if [ -n "$ERROR_MSGS" ]; then
                    echo "Recent error messages:" | tee -a "$LOG_FILE"
                    echo "$ERROR_MSGS" | tee -a "$LOG_FILE"
                    echo "" | tee -a "$LOG_FILE"
                fi
            fi
        fi
        
        ITERATION_COUNT=$((ITERATION_COUNT + 1))
        sleep 60
    done
    
    echo "" | tee -a "$LOG_FILE"
    echo "Gubbins process completed at $(date)" | tee -a "$LOG_FILE"
    
else
    echo "Gubbins process not found. Monitoring system resources..." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Monitor system resources for 30 minutes
    for i in {1..30}; do
        TIMESTAMP=$(date '+%H:%M:%S')
        SYSTEM_MEM_USED=$(free | grep '^Mem:' | awk '{printf "%.1f%%", $3/$2 * 100.0}')
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        
        echo "$TIMESTAMP | System CPU: $CPU_USAGE% | System Memory: $SYSTEM_MEM_USED" | tee -a "$LOG_FILE"
        sleep 60
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
    MAX_MEM=$(grep -E "^[0-9]{2}:[0-9]{2}:[0-9]{2}" "$LOG_FILE" | awk '{print $5}' | sed 's/GB//' | sort -n | tail -1)
    if [ -n "$MAX_MEM" ] && [ "$MAX_MEM" != "N/A" ]; then
        echo "Maximum memory used by Gubbins: ${MAX_MEM} GB" | tee -a "$LOG_FILE"
        
        if [ "$MAX_MEM" -lt 100 ]; then
            echo "WARNING: Gubbins used less than 100GB memory. This suggests:" | tee -a "$LOG_FILE"
            echo "  - Memory allocation issues in the container" | tee -a "$LOG_FILE"
            echo "  - Gubbins falling back to lightweight mode" | tee -a "$LOG_FILE"
            echo "  - Process terminating early due to errors" | tee -a "$LOG_FILE"
        fi
    fi
fi

echo "" | tee -a "$LOG_FILE"
echo "Recommendations:" | tee -a "$LOG_FILE"
echo "================" | tee -a "$LOG_FILE"
echo "If Gubbins used <100GB memory with 1300GB allocated:" | tee -a "$LOG_FILE"
echo "1. Check container memory limits" | tee -a "$LOG_FILE"
echo "2. Review Gubbins logs for early termination" | tee -a "$LOG_FILE"
echo "3. Consider using different Gubbins parameters" | tee -a "$LOG_FILE"
echo "4. Verify Docker memory allocation settings" | tee -a "$LOG_FILE"