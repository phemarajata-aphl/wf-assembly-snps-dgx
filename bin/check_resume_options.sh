#!/bin/bash

# Script to check available resume options for the wf-assembly-snps pipeline
# Usage: ./bin/check_resume_options.sh <parsnp_outputs_dir> <output_dir>

PARSNP_DIR="$1"
OUTPUT_DIR="$2"

if [ -z "$PARSNP_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <parsnp_outputs_directory> <output_directory>"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/parsnp_outputs /path/to/results"
    echo "  $0 /mnt/disks/ngs-data/parsnp-dgx /mnt/disks/ngs-data/results"
    exit 1
fi

echo "Resume Options Analysis"
echo "======================"
echo "ParSNP outputs directory: $PARSNP_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if directories exist
if [ ! -d "$PARSNP_DIR" ]; then
    echo "❌ ERROR: ParSNP outputs directory does not exist: $PARSNP_DIR"
    exit 1
fi

echo "✓ ParSNP outputs directory exists"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "⚠️  Output directory does not exist: $OUTPUT_DIR"
    echo "   This is normal for a first run"
else
    echo "✓ Output directory exists"
fi

echo ""

# Check for key files
echo "File Availability Check:"
echo "========================"

# ParSNP outputs
PARSNP_GGR="$PARSNP_DIR/Parsnp.ggr"
PARSNP_TREE="$PARSNP_DIR/Parsnp.tree"
PARSNP_ALIGNMENT_PARSNP="$PARSNP_DIR/Parsnp.Core_Alignment.fasta"

echo "ParSNP outputs:"
if [ -f "$PARSNP_GGR" ]; then
    echo "  ✓ Parsnp.ggr (required for GINGR conversion)"
else
    echo "  ❌ Parsnp.ggr (missing - needed for GINGR conversion)"
fi

if [ -f "$PARSNP_TREE" ]; then
    echo "  ✓ Parsnp.tree (required for recombination)"
else
    echo "  ❌ Parsnp.tree (missing - needed for recombination)"
fi

if [ -f "$PARSNP_ALIGNMENT_PARSNP" ]; then
    echo "  ✓ Parsnp.Core_Alignment.fasta (can skip GINGR conversion)"
else
    echo "  ⚠️  Parsnp.Core_Alignment.fasta (not found - GINGR conversion needed)"
fi

echo ""

# Check output directory for existing files
PARSNP_ALIGNMENT_OUTPUT="$OUTPUT_DIR/Parsnp/Parsnp.Core_Alignment.fasta"
GUBBINS_OUTPUT="$OUTPUT_DIR/Parsnp/Gubbins"
CLONALFRAMEML_OUTPUT="$OUTPUT_DIR/Parsnp/ClonalFrameML"

echo "Previous run outputs:"
if [ -f "$PARSNP_ALIGNMENT_OUTPUT" ]; then
    echo "  ✓ $PARSNP_ALIGNMENT_OUTPUT (can skip GINGR conversion)"
else
    echo "  ⚠️  $PARSNP_ALIGNMENT_OUTPUT (not found)"
fi

if [ -d "$GUBBINS_OUTPUT" ]; then
    echo "  ✓ Gubbins output directory exists"
    if [ -f "$GUBBINS_OUTPUT/Parsnp-Gubbins.recombination_positions.txt" ]; then
        echo "    ✓ Gubbins recombination results found"
    fi
else
    echo "  ⚠️  Gubbins output directory not found"
fi

if [ -d "$CLONALFRAMEML_OUTPUT" ]; then
    echo "  ✓ ClonalFrameML output directory exists"
    if [ -f "$CLONALFRAMEML_OUTPUT/Parsnp-ClonalFrameML.recombination_positions.txt" ]; then
        echo "    ✓ ClonalFrameML recombination results found"
    fi
else
    echo "  ⚠️  ClonalFrameML output directory not found"
fi

echo ""

# Provide recommendations
echo "Resume Recommendations:"
echo "======================"

CAN_SKIP_GINGR=false
if [ -f "$PARSNP_ALIGNMENT_PARSNP" ] || [ -f "$PARSNP_ALIGNMENT_OUTPUT" ]; then
    CAN_SKIP_GINGR=true
fi

if [ "$CAN_SKIP_GINGR" = true ]; then
    echo "✅ You can skip GINGR conversion!"
    echo ""
    echo "Option 1: Auto-detect existing alignment (recommended)"
    echo "  nextflow run main.nf \\"
    echo "    -profile google_vm_large \\"
    echo "    --parsnp_outputs $PARSNP_DIR \\"
    echo "    --outdir $OUTPUT_DIR \\"
    echo "    --recombination gubbins"
    echo ""
    echo "Option 2: Explicitly skip GINGR conversion"
    echo "  nextflow run main.nf \\"
    echo "    -profile google_vm_large \\"
    echo "    --parsnp_outputs $PARSNP_DIR \\"
    echo "    --outdir $OUTPUT_DIR \\"
    echo "    --recombination gubbins \\"
    echo "    --skip_gingr_conversion"
    echo ""
    echo "Option 3: Specify exact alignment file"
    if [ -f "$PARSNP_ALIGNMENT_OUTPUT" ]; then
        echo "  nextflow run main.nf \\"
        echo "    -profile google_vm_large \\"
        echo "    --parsnp_outputs $PARSNP_DIR \\"
        echo "    --outdir $OUTPUT_DIR \\"
        echo "    --recombination gubbins \\"
        echo "    --alignment_file $PARSNP_ALIGNMENT_OUTPUT"
    elif [ -f "$PARSNP_ALIGNMENT_PARSNP" ]; then
        echo "  nextflow run main.nf \\"
        echo "    -profile google_vm_large \\"
        echo "    --parsnp_outputs $PARSNP_DIR \\"
        echo "    --outdir $OUTPUT_DIR \\"
        echo "    --recombination gubbins \\"
        echo "    --alignment_file $PARSNP_ALIGNMENT_PARSNP"
    fi
else
    echo "⚠️  GINGR conversion is required"
    echo ""
    echo "Standard command (will run GINGR conversion):"
    echo "  nextflow run main.nf \\"
    echo "    -profile google_vm_large \\"
    echo "    --parsnp_outputs $PARSNP_DIR \\"
    echo "    --outdir $OUTPUT_DIR \\"
    echo "    --recombination gubbins"
fi

echo ""
echo "For ClonalFrameML, replace '--recombination gubbins' with '--recombination clonalframeml'"
echo ""

# Performance tips
echo "Performance Tips:"
echo "================"
echo "• The pipeline will automatically detect and use existing alignment files"
echo "• Use --skip_gingr_conversion to force skipping GINGR conversion"
echo "• Use --alignment_file to specify an exact alignment file path"
echo "• Both Gubbins and ClonalFrameML can benefit from skipping GINGR conversion"
echo "• Check the Nextflow log for 'Auto-detected resume point' messages"