#!/bin/bash

# Script to monitor Gubbins memory usage and provide diagnostics
# Usage: ./bin/monitor_gubbins_memory.sh [work_directory]

WORK_DIR="${1:-work}"
LOG_FILE="${WORK_DIR}/gubbins_memory_monitor.log"

echo "Gubbins Memory Monitor" | tee "$LOG_FILE"
echo "=====================" | tee -a "$LOG_FILE"
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
    
    # Monitor resources every 30 seconds
    echo "Resource Usage Monitoring:" | tee -a "$LOG_FILE"
    echo "=========================" | tee -a "$LOG_FILE"
    echo "Time | CPU% | Memory(RSS) | Memory(VSZ) | System Memory Used | Allocated Memory" | tee -a "$LOG_FILE"
    echo "-----+------+-------------+-------------+-------------------+-----------------" | tee -a "$LOG_FILE"
    
    # Try to find allocated memory from Nextflow task
    ALLOCATED_MEMORY="Unknown"
    if [ -d "$WORK_DIR" ]; then
        TASK_DIR=$(find "$WORK_DIR" -name ".command.run" -exec dirname {} \; | head -1)
        if [ -n "$TASK_DIR" ] && [ -f "$TASK_DIR/.command.run" ]; then
            ALLOCATED_MEMORY=$(grep -o "memory.*GB\|memory.*MB" "$TASK_DIR/.command.run" | head -1 || echo "Unknown")
        fi
    fi
    
    while kill -0 "$GUBBINS_PID" 2>/dev/null; do
        TIMESTAMP=$(date '+%H:%M:%S')
        
        # Get process-specific stats
        if [ -f "/proc/$GUBBINS_PID/stat" ]; then
            CPU_PERCENT=$(ps -p "$GUBBINS_PID" -o %cpu --no-headers | tr -d ' ')
            MEMORY_RSS=$(ps -p "$GUBBINS_PID" -o rss --no-headers | tr -d ' ')
            MEMORY_VSZ=$(ps -p "$GUBBINS_PID" -o vsz --no-headers | tr -d ' ')
            
            # Convert KB to human readable
            MEMORY_RSS_GB=$(echo "scale=2; $MEMORY_RSS / 1024 / 1024" | bc -l 2>/dev/null || echo "N/A")
            MEMORY_VSZ_GB=$(echo "scale=2; $MEMORY_VSZ / 1024 / 1024" | bc -l 2>/dev/null || echo "N/A")
        else
            CPU_PERCENT="N/A"
            MEMORY_RSS_GB="N/A"
            MEMORY_VSZ_GB="N/A"
        fi
        
        # Get system memory usage
        SYSTEM_MEM_USED=$(free | grep '^Mem:' | awk '{printf "%.1f%%", $3/$2 * 100.0}')
        
        printf "%s | %5s | %8s GB | %8s GB | %s | %s\n" \
            "$TIMESTAMP" "$CPU_PERCENT" "$MEMORY_RSS_GB" "$MEMORY_VSZ_GB" "$SYSTEM_MEM_USED" "$ALLOCATED_MEMORY" | tee -a "$LOG_FILE"
        
        sleep 30
    done
    
    echo "" | tee -a "$LOG_FILE"
    echo "Gubbins process completed at $(date)" | tee -a "$LOG_FILE"
    
else
    echo "Gubbins process not found. Monitoring system resources..." | tee -a "$LOG_FILE"
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

# Check for Gubbins-specific issues
echo "Gubbins Diagnostics:" | tee -a "$LOG_FILE"
echo "===================" | tee -a "$LOG_FILE"

# Check for common Gubbins issues
if [ -d "$WORK_DIR" ]; then
    # Look for Gubbins error messages
    GUBBINS_ERRORS=$(find "$WORK_DIR" -name ".command.err" -exec grep -l "gubbins\|Gubbins" {} \; 2>/dev/null | head -5)
    
    if [ -n "$GUBBINS_ERRORS" ]; then
        echo "Found Gubbins-related error files:" | tee -a "$LOG_FILE"
        echo "$GUBBINS_ERRORS" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "Sample error messages:" | tee -a "$LOG_FILE"
        head -10 $(echo "$GUBBINS_ERRORS" | head -1) 2>/dev/null | tee -a "$LOG_FILE"
    else
        echo "No Gubbins error files found" | tee -a "$LOG_FILE"
    fi
    
    # Check for memory-related messages
    MEMORY_ERRORS=$(find "$WORK_DIR" -name ".command.*" -exec grep -l "out of memory\|killed\|bus error\|segmentation fault" {} \; 2>/dev/null | head -3)
    
    if [ -n "$MEMORY_ERRORS" ]; then
        echo "" | tee -a "$LOG_FILE"
        echo "Found memory-related error files:" | tee -a "$LOG_FILE"
        echo "$MEMORY_ERRORS" | tee -a "$LOG_FILE"
    fi
fi

echo "" | tee -a "$LOG_FILE"
echo "Monitoring completed at $(date)" | tee -a "$LOG_FILE"

# Summary and recommendations
echo "" | tee -a "$LOG_FILE"
echo "Summary and Recommendations:" | tee -a "$LOG_FILE"
echo "============================" | tee -a "$LOG_FILE"

if [ -f "$LOG_FILE" ]; then
    MAX_MEM=$(grep -E "^[0-9]{2}:[0-9]{2}:[0-9]{2}" "$LOG_FILE" | awk '{print $5}' | sed 's/GB//' | sort -n | tail -1)
    if [ -n "$MAX_MEM" ] && [ "$MAX_MEM" != "N/A" ]; then
        echo "Maximum memory used by Gubbins: ${MAX_MEM} GB" | tee -a "$LOG_FILE"
        
        # Provide recommendations based on memory usage
        if (( $(echo "$MAX_MEM < 50" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠️  LOW MEMORY USAGE: Gubbins used less than 50GB" | tee -a "$LOG_FILE"
            echo "   This suggests Gubbins may have failed early or hit a container limit" | tee -a "$LOG_FILE"
            echo "   Recommendations:" | tee -a "$LOG_FILE"
            echo "   - Check Gubbins error logs for specific failure reasons" | tee -a "$LOG_FILE"
            echo "   - Verify container has access to allocated memory" | tee -a "$LOG_FILE"
            echo "   - Consider using a different Gubbins container version" | tee -a "$LOG_FILE"
        elif (( $(echo "$MAX_MEM < 200" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠️  MODERATE MEMORY USAGE: Gubbins used ${MAX_MEM}GB" | tee -a "$LOG_FILE"
            echo "   This is reasonable for smaller datasets but low for 300+ genomes" | tee -a "$LOG_FILE"
        else
            echo "✅ GOOD MEMORY USAGE: Gubbins used ${MAX_MEM}GB" | tee -a "$LOG_FILE"
            echo "   This indicates proper memory utilization" | tee -a "$LOG_FILE"
        fi
    fi
fi

echo "" | tee -a "$LOG_FILE"
echo "Log file saved to: $LOG_FILE" | tee -a "$LOG_FILE"