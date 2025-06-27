#!/bin/bash

# Script to copy ParSNP outputs from work directory to a dedicated directory
# Usage: ./copy_parsnp_outputs.sh <source_work_dir> <destination_dir>

SOURCE_DIR="$1"
DEST_DIR="$2"

if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "Usage: $0 <source_work_dir> <destination_dir>"
    echo "Example: $0 /home/cdcadmin/wf-assembly-snps/work/bf/5ff40d9bddcc203d095c44320909b1 ./parsnp_outputs"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

echo "Copying ParSNP output files from $SOURCE_DIR to $DEST_DIR"

# Copy the main ParSNP output files
cp "$SOURCE_DIR/Parsnp.ggr" "$DEST_DIR/" 2>/dev/null && echo "✓ Copied Parsnp.ggr"
cp "$SOURCE_DIR/Parsnp.SNP_Distances_Matrix.tsv" "$DEST_DIR/" 2>/dev/null && echo "✓ Copied Parsnp.SNP_Distances_Matrix.tsv"
cp "$SOURCE_DIR/Parsnp.SNPs.fa.gz" "$DEST_DIR/" 2>/dev/null && echo "✓ Copied Parsnp.SNPs.fa.gz"
cp "$SOURCE_DIR/Parsnp.tree" "$DEST_DIR/" 2>/dev/null && echo "✓ Copied Parsnp.tree"
cp "$SOURCE_DIR/Parsnp.xmfa" "$DEST_DIR/" 2>/dev/null && echo "✓ Copied Parsnp.xmfa"
cp "$SOURCE_DIR/versions.yml" "$DEST_DIR/" 2>/dev/null && echo "✓ Copied versions.yml"

echo ""
echo "Files copied to: $DEST_DIR"
echo "Contents:"
ls -la "$DEST_DIR"

echo ""
echo "You can now run the pipeline with:"
echo "nextflow run main.nf \\"
echo "  -profile <your_profile> \\"
echo "  --input <your_input_dir> \\"
echo "  --outdir <your_output_dir> \\"
echo "  --parsnp_outputs $DEST_DIR \\"
echo "  --snp_package parsnp"