#!/bin/bash

# Script to diagnose why Gubbins is falling back to lightweight mode
# Usage: ./bin/diagnose_gubbins_fallback.sh [work_directory]

WORK_DIR="${1:-work}"

echo "Gubbins Fallback Diagnostic Tool"
echo "================================"
echo "Work directory: $WORK_DIR"
echo ""

# Check if work directory exists
if [ ! -d "$WORK_DIR" ]; then
    echo "❌ Work directory not found: $WORK_DIR"
    echo "Please provide the correct work directory path"
    exit 1
fi

echo "System Information:"
echo "=================="
echo "Total Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "Available Memory: $(free -h | grep '^Mem:' | awk '{print $7}')"
echo "Total CPUs: $(nproc)"
echo ""

echo "Docker Information:"
echo "=================="
if command -v docker &> /dev/null; then
    echo "Docker version: $(docker --version)"
    echo "Docker daemon running: $(docker info >/dev/null 2>&1 && echo 'Yes' || echo 'No')"
    
    # Check Docker memory limits
    DOCKER_MEMORY=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3 $4}')
    if [ -n "$DOCKER_MEMORY" ]; then
        echo "Docker total memory: $DOCKER_MEMORY"
    fi
else
    echo "Docker not found"
fi
echo ""

echo "Searching for Gubbins-related processes:"
echo "========================================"
GUBBINS_DIRS=$(find "$WORK_DIR" -type d -name "*" -exec grep -l "RECOMBINATION_GUBBINS\|run_gubbins" {}/.command.sh 2>/dev/null \; | head -10)

if [ -n "$GUBBINS_DIRS" ]; then
    echo "Found Gubbins work directories:"
    for dir in $GUBBINS_DIRS; do
        WORK_SUBDIR=$(dirname "$dir")
        echo "  $WORK_SUBDIR"
        
        # Check command output and error logs
        if [ -f "$WORK_SUBDIR/.command.out" ]; then
            echo "    Command output exists: $(wc -l < "$WORK_SUBDIR/.command.out") lines"
            
            # Check for fallback messages
            if grep -q "lightweight fallback\|Lightweight fallback" "$WORK_SUBDIR/.command.out"; then
                echo "    ⚠️  FALLBACK DETECTED in this directory"
                
                # Show the reason for fallback
                echo "    Fallback reason:"
                grep -A 5 -B 5 "lightweight fallback\|Lightweight fallback" "$WORK_SUBDIR/.command.out" | sed 's/^/      /'
                echo ""
                
                # Check for memory usage information
                if grep -q "Allocated memory\|Available memory" "$WORK_SUBDIR/.command.out"; then
                    echo "    Memory allocation info:"
                    grep "Allocated memory\|Available memory" "$WORK_SUBDIR/.command.out" | sed 's/^/      /'
                fi
                
                # Check for Gubbins failure messages
                if grep -q "Gubbins.*failed\|run_gubbins.py.*failed" "$WORK_SUBDIR/.command.out"; then
                    echo "    Gubbins failure messages:"
                    grep "Gubbins.*failed\|run_gubbins.py.*failed" "$WORK_SUBDIR/.command.out" | sed 's/^/      /'
                fi
                
                # Check error log
                if [ -f "$WORK_SUBDIR/.command.err" ]; then
                    echo "    Error log size: $(wc -l < "$WORK_SUBDIR/.command.err") lines"
                    if [ -s "$WORK_SUBDIR/.command.err" ]; then
                        echo "    Recent errors:"
                        tail -10 "$WORK_SUBDIR/.command.err" | sed 's/^/      /'
                    fi
                fi
                echo ""
            else
                echo "    ✓ No fallback detected in this directory"
                
                # Check if Gubbins is still running or completed successfully
                if grep -q "Gubbins completed successfully" "$WORK_SUBDIR/.command.out"; then
                    echo "    ✓ Gubbins completed successfully"
                elif grep -q "run_gubbins.py" "$WORK_SUBDIR/.command.out"; then
                    echo "    ⏳ Gubbins appears to be running or was attempted"
                    
                    # Show last few lines of output
                    echo "    Last output lines:"
                    tail -5 "$WORK_SUBDIR/.command.out" | sed 's/^/      /'
                fi
            fi
        fi
        
        # Check the command script for allocated resources
        if [ -f "$WORK_SUBDIR/.command.sh" ]; then
            echo "    Checking allocated resources in command script..."
            
            # Look for memory and CPU information in the script
            MEMORY_INFO=$(grep -i "memory\|ram" "$WORK_SUBDIR/.command.sh" | head -3)
            if [ -n "$MEMORY_INFO" ]; then
                echo "    Memory-related settings:"
                echo "$MEMORY_INFO" | sed 's/^/      /'
            fi
        fi
        
        echo ""
    done
else
    echo "❌ No Gubbins work directories found"
    echo "This could mean:"
    echo "  - Gubbins hasn't run yet"
    echo "  - Work directory path is incorrect"
    echo "  - Pipeline is using a different recombination method"
fi

echo ""
echo "Checking for common issues:"
echo "=========================="

# Check for memory-related errors
MEMORY_ERRORS=$(find "$WORK_DIR" -name ".command.err" -exec grep -l "out of memory\|memory.*error\|killed.*memory" {} \; 2>/dev/null)
if [ -n "$MEMORY_ERRORS" ]; then
    echo "❌ Found memory-related errors in:"
    echo "$MEMORY_ERRORS" | sed 's/^/  /'
else
    echo "✓ No obvious memory errors found"
fi

# Check for permission issues
PERMISSION_ERRORS=$(find "$WORK_DIR" -name ".command.err" -exec grep -l "permission denied\|cannot access" {} \; 2>/dev/null)
if [ -n "$PERMISSION_ERRORS" ]; then
    echo "❌ Found permission errors in:"
    echo "$PERMISSION_ERRORS" | sed 's/^/  /'
else
    echo "✓ No permission errors found"
fi

# Check for container issues
CONTAINER_ERRORS=$(find "$WORK_DIR" -name ".command.err" -exec grep -l "docker.*error\|container.*error" {} \; 2>/dev/null)
if [ -n "$CONTAINER_ERRORS" ]; then
    echo "❌ Found container errors in:"
    echo "$CONTAINER_ERRORS" | sed 's/^/  /'
else
    echo "✓ No container errors found"
fi

echo ""
echo "Recommendations:"
echo "==============="
echo "If Gubbins is falling back to lightweight mode:"
echo ""
echo "1. **Check memory allocation**:"
echo "   - Verify Docker has access to sufficient memory"
echo "   - Check if container memory limits are set correctly"
echo "   - Monitor actual memory usage during Gubbins execution"
echo ""
echo "2. **Monitor Gubbins execution**:"
echo "   ./bin/monitor_gubbins_performance.sh $WORK_DIR"
echo ""
echo "3. **Check Gubbins parameters**:"
echo "   - Large datasets (300+ genomes) may need different parameters"
echo "   - Consider reducing thread count if memory is limited"
echo "   - Try different Gubbins model settings"
echo ""
echo "4. **Verify system resources**:"
echo "   - Ensure VM has sufficient memory (1400GB+ for large datasets)"
echo "   - Check that Docker daemon has proper resource limits"
echo "   - Monitor system memory usage during execution"
echo ""
echo "5. **Alternative approaches**:"
echo "   - Use ClonalFrameML instead: --recombination clonalframeml"
echo "   - Force lightweight method: --recombination_method lightweight"
echo "   - Split large datasets into smaller batches"
echo ""
echo "6. **Debug commands**:"
echo "   # Check Docker memory limits"
echo "   docker info | grep -i memory"
echo ""
echo "   # Monitor memory usage in real-time"
echo "   watch -n 5 'free -h && docker stats --no-stream'"
echo ""
echo "   # Check Nextflow resource allocation"
echo "   grep -r \"memory.*GB\" $WORK_DIR/*/.*command.sh"