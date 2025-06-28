#!/bin/bash

# Script to verify ParSNP outputs are compatible with both Gubbins and ClonalFrameML
# Usage: ./bin/check_parsnp_outputs.sh <parsnp_outputs_directory>

PARSNP_DIR="$1"

if [ -z "$PARSNP_DIR" ]; then
    echo "Usage: $0 <parsnp_outputs_directory>"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/parsnp_outputs/"
    echo "  $0 /mnt/disks/ngs_data/parsnp-dgx"
    exit 1
fi

echo "ParSNP Outputs Compatibility Check"
echo "=================================="
echo "Directory: $PARSNP_DIR"
echo ""

# Check if directory exists
if [ ! -d "$PARSNP_DIR" ]; then
    echo "❌ ERROR: Directory $PARSNP_DIR does not exist"
    exit 1
fi

echo "✓ Directory exists: $PARSNP_DIR"
echo ""

# Required files for basic functionality
REQUIRED_FILES=(
    "Parsnp.ggr"
    "Parsnp.SNP_Distances_Matrix.tsv"
    "Parsnp.SNPs.fa.gz"
    "Parsnp.tree"
    "Parsnp.xmfa"
    "versions.yml"
)

# Files that should NOT be present (to avoid conflicts)
CONFLICTING_FILES=(
    "Parsnp.Core_Alignment.fasta"
)

echo "Checking for required files:"
echo "----------------------------"

ALL_REQUIRED_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PARSNP_DIR/$file" ]; then
        echo "✓ Found: $file"
    else
        echo "❌ Missing: $file"
        ALL_REQUIRED_PRESENT=false
    fi
done

echo ""
echo "Checking for conflicting files:"
echo "-------------------------------"

CONFLICTS_FOUND=false
for file in "${CONFLICTING_FILES[@]}"; do
    if [ -f "$PARSNP_DIR/$file" ]; then
        echo "⚠️  Found conflicting file: $file"
        echo "   This file will be automatically filtered out during resume workflow"
        CONFLICTS_FOUND=true
    else
        echo "✓ No conflict: $file (not present)"
    fi
done

echo ""
echo "Recombination method compatibility:"
echo "-----------------------------------"

# Check tree file specifically for recombination methods
if [ -f "$PARSNP_DIR/Parsnp.tree" ]; then
    echo "✓ Gubbins compatible: Parsnp.tree found"
    echo "✓ ClonalFrameML compatible: Parsnp.tree found"
    
    # Check tree file size and content
    TREE_SIZE=$(stat -f%z "$PARSNP_DIR/Parsnp.tree" 2>/dev/null || stat -c%s "$PARSNP_DIR/Parsnp.tree" 2>/dev/null || echo "0")
    if [ "$TREE_SIZE" -gt 0 ]; then
        echo "✓ Tree file is not empty ($TREE_SIZE bytes)"
        
        # Check if tree file contains valid Newick format
        if grep -q "(" "$PARSNP_DIR/Parsnp.tree" && grep -q ")" "$PARSNP_DIR/Parsnp.tree"; then
            echo "✓ Tree file appears to contain valid Newick format"
        else
            echo "⚠️  Tree file may not contain valid Newick format"
        fi
    else
        echo "❌ Tree file is empty"
        ALL_REQUIRED_PRESENT=false
    fi
else
    echo "❌ Gubbins: Parsnp.tree missing"
    echo "❌ ClonalFrameML: Parsnp.tree missing"
    ALL_REQUIRED_PRESENT=false
fi

echo ""
echo "Directory contents:"
echo "-------------------"
ls -la "$PARSNP_DIR"

echo ""
echo "Summary:"
echo "========"

if [ "$ALL_REQUIRED_PRESENT" = true ]; then
    echo "✅ All required files are present!"
    echo ""
    echo "Your ParSNP outputs are compatible with both recombination methods:"
    echo ""
    echo "For Gubbins:"
    echo "  nextflow run main.nf \\"
    echo "    -profile google_vm_large \\"
    echo "    --parsnp_outputs $PARSNP_DIR \\"
    echo "    --outdir results_gubbins \\"
    echo "    --recombination gubbins \\"
    echo "    --max_memory 1400.GB"
    echo ""
    echo "For ClonalFrameML:"
    echo "  nextflow run main.nf \\"
    echo "    -profile google_vm_large \\"
    echo "    --parsnp_outputs $PARSNP_DIR \\"
    echo "    --outdir results_clonalframeml \\"
    echo "    --recombination clonalframeml \\"
    echo "    --max_memory 1400.GB"
    
    if [ "$CONFLICTS_FOUND" = true ]; then
        echo ""
        echo "Note: Conflicting files were found but will be automatically handled."
    fi
else
    echo "❌ Some required files are missing."
    echo ""
    echo "Missing files must be present for the resume workflow to work properly."
    echo "Please ensure your ParSNP run completed successfully and all output files are present."
fi

echo ""
echo "Troubleshooting:"
echo "================"
echo "If you encounter issues with ClonalFrameML:"
echo "1. Ensure Parsnp.tree file is present and not empty"
echo "2. Check that the tree file contains valid Newick format"
echo "3. Verify all ParSNP output files are in the same directory"
echo ""
echo "If you encounter issues with Gubbins:"
echo "1. Ensure Parsnp.tree file is present"
echo "2. Consider using --recombination_method lightweight for very large datasets"
echo "3. Check memory requirements for your dataset size"