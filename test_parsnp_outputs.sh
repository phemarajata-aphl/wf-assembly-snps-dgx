#!/bin/bash

# Test script to verify ParSNP outputs are properly detected
# Usage: ./test_parsnp_outputs.sh <parsnp_outputs_directory>

PARSNP_DIR="$1"

if [ -z "$PARSNP_DIR" ]; then
    echo "Usage: $0 <parsnp_outputs_directory>"
    echo "Example: $0 ./parsnp_outputs"
    exit 1
fi

echo "Testing ParSNP outputs directory: $PARSNP_DIR"
echo "================================================"

# Check if directory exists
if [ ! -d "$PARSNP_DIR" ]; then
    echo "❌ ERROR: Directory $PARSNP_DIR does not exist"
    exit 1
fi

echo "✓ Directory exists: $PARSNP_DIR"

# Required files
REQUIRED_FILES=(
    "Parsnp.ggr"
    "Parsnp.SNP_Distances_Matrix.tsv"
    "Parsnp.SNPs.fa.gz"
    "Parsnp.tree"
    "Parsnp.xmfa"
    "versions.yml"
)

echo ""
echo "Checking for required files:"
echo "----------------------------"

ALL_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PARSNP_DIR/$file" ]; then
        echo "✓ Found: $file"
    else
        echo "❌ Missing: $file"
        ALL_PRESENT=false
    fi
done

echo ""
echo "Directory contents:"
echo "-------------------"
ls -la "$PARSNP_DIR"

echo ""
if [ "$ALL_PRESENT" = true ]; then
    echo "✅ All required files are present!"
    echo ""
    echo "You can now run the pipeline with:"
    echo "nextflow run main.nf \\"
    echo "  -profile large_dataset \\"
    echo "  --input /path/to/your/genomes \\"
    echo "  --outdir results_resumed \\"
    echo "  --parsnp_outputs $PARSNP_DIR \\"
    echo "  --snp_package parsnp \\"
    echo "  --recombination gubbins \\"
    echo "  --max_memory 480.GB"
else
    echo "❌ Some required files are missing. Please ensure all ParSNP output files are present."
fi