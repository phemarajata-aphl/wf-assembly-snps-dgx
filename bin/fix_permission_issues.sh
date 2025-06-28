#!/bin/bash

# Script to diagnose and fix permission issues in wf-assembly-snps pipeline
# Usage: ./bin/fix_permission_issues.sh [work_directory]

WORK_DIR="${1:-work}"

echo "Permission Issues Diagnostic and Fix Tool"
echo "========================================"
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
echo "Current user: $(whoami)"
echo "Current UID: $(id -u)"
echo "Current GID: $(id -g)"
echo "Current groups: $(groups)"
echo ""

echo "Docker Information:"
echo "=================="
if command -v docker &> /dev/null; then
    echo "Docker version: $(docker --version)"
    echo "Docker daemon running: $(docker info >/dev/null 2>&1 && echo 'Yes' || echo 'No')"
else
    echo "Docker not found"
fi
echo ""

echo "Checking Work Directory Permissions:"
echo "===================================="
echo "Work directory owner: $(stat -c '%U:%G' "$WORK_DIR" 2>/dev/null || stat -f '%Su:%Sg' "$WORK_DIR" 2>/dev/null)"
echo "Work directory permissions: $(stat -c '%a' "$WORK_DIR" 2>/dev/null || stat -f '%A' "$WORK_DIR" 2>/dev/null)"
echo ""

# Find problematic files
echo "Finding Files with Permission Issues:"
echo "===================================="
PROBLEM_FILES=$(find "$WORK_DIR" -type f \( -name "*.tree" -o -name "*.txt" -o -name "*.gff" \) ! -readable 2>/dev/null | head -10)

if [ -n "$PROBLEM_FILES" ]; then
    echo "Found files with permission issues:"
    echo "$PROBLEM_FILES"
    echo ""
    
    echo "File details:"
    echo "$PROBLEM_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            echo "  $file:"
            echo "    Owner: $(stat -c '%U:%G' "$file" 2>/dev/null || stat -f '%Su:%Sg' "$file" 2>/dev/null)"
            echo "    Permissions: $(stat -c '%a' "$file" 2>/dev/null || stat -f '%A' "$file" 2>/dev/null)"
        fi
    done
else
    echo "✓ No obvious permission issues found with output files"
fi

echo ""

# Check for rsync-related issues
echo "Checking for rsync-related issues:"
echo "=================================="
RSYNC_ERRORS=$(find "$WORK_DIR" -name ".command.err" -exec grep -l "rsync.*Permission denied" {} \; 2>/dev/null | head -5)

if [ -n "$RSYNC_ERRORS" ]; then
    echo "Found rsync permission errors in:"
    echo "$RSYNC_ERRORS"
    echo ""
    echo "Sample error:"
    head -5 $(echo "$RSYNC_ERRORS" | head -1) 2>/dev/null
else
    echo "✓ No rsync permission errors found"
fi

echo ""

# Provide solutions
echo "Solutions:"
echo "=========="

if [ -n "$PROBLEM_FILES" ] || [ -n "$RSYNC_ERRORS" ]; then
    echo "1. Use the safe profile (recommended):"
    echo "   nextflow run main.nf -profile google_vm_large_safe [other options]"
    echo ""
    
    echo "2. Fix permissions manually:"
    echo "   sudo chown -R $(whoami):$(id -gn) $WORK_DIR"
    echo "   chmod -R 755 $WORK_DIR"
    echo ""
    
    echo "3. Clean work directory and restart:"
    echo "   rm -rf $WORK_DIR"
    echo "   nextflow run main.nf -profile google_vm_large_safe [other options]"
    echo ""
    
    echo "4. Use alternative staging mode:"
    echo "   Add to your nextflow.config:"
    echo "   process.stageOutMode = 'copy'"
    echo ""
    
    echo "5. Check Docker daemon permissions:"
    echo "   sudo usermod -aG docker $(whoami)"
    echo "   # Then log out and log back in"
    
else
    echo "✓ No permission issues detected"
    echo ""
    echo "If you're still experiencing issues:"
    echo "1. Use the safe profile: -profile google_vm_large_safe"
    echo "2. Check the Nextflow log for specific error messages"
    echo "3. Ensure Docker daemon is running with proper permissions"
fi

echo ""

# Provide prevention tips
echo "Prevention Tips:"
echo "==============="
echo "• Use the google_vm_large_safe profile for better permission handling"
echo "• Ensure your user is in the docker group"
echo "• Run Nextflow with consistent user permissions"
echo "• Avoid running as root unless necessary"
echo "• Use absolute paths for input/output directories"
echo ""

echo "Profile Recommendations:"
echo "========================"
echo "For Google Cloud VM Large instances:"
echo ""
echo "Standard (may have permission issues):"
echo "  -profile google_vm_large"
echo ""
echo "Safe (recommended for permission issues):"
echo "  -profile google_vm_large_safe"
echo ""
echo "The 'safe' profile uses copy mode instead of rsync for file staging,"
echo "which avoids most permission-related issues."