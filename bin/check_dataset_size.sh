#!/bin/bash

# Script to help users determine the best recombination method for their dataset
# Usage: ./bin/check_dataset_size.sh <input_directory_or_alignment_file>

INPUT="$1"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <input_directory_or_alignment_file>"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/genomes/"
    echo "  $0 /path/to/alignment.fasta"
    echo "  $0 /path/to/parsnp_outputs/Parsnp.Core_Alignment.fasta"
    exit 1
fi

echo "Dataset Size Analysis"
echo "===================="

# Count genomes
if [ -d "$INPUT" ]; then
    # Count FASTA files in directory
    GENOME_COUNT=$(find "$INPUT" -name "*.fasta" -o -name "*.fas" -o -name "*.fna" -o -name "*.fa" | wc -l)
    echo "Input type: Directory"
    echo "Genome files found: $GENOME_COUNT"
elif [ -f "$INPUT" ]; then
    # Count sequences in alignment file
    GENOME_COUNT=$(grep -c "^>" "$INPUT" 2>/dev/null || echo "0")
    echo "Input type: Alignment file"
    echo "Sequences in alignment: $GENOME_COUNT"
else
    echo "ERROR: Input '$INPUT' not found or not accessible"
    exit 1
fi

echo ""
echo "Recommendations:"
echo "================"

if [ "$GENOME_COUNT" -lt 50 ]; then
    echo "✓ Small dataset ($GENOME_COUNT genomes)"
    echo "  Recommended profile: -profile docker"
    echo "  Recommended recombination: --recombination gubbins"
    echo ""
    echo "  Command:"
    echo "  nextflow run main.nf -profile docker --input $INPUT --outdir results --recombination gubbins"
    
elif [ "$GENOME_COUNT" -lt 200 ]; then
    echo "✓ Medium dataset ($GENOME_COUNT genomes)"
    echo "  Recommended profile: -profile large_dataset"
    echo "  Recommended recombination: --recombination gubbins"
    echo ""
    echo "  Command:"
    echo "  nextflow run main.nf -profile large_dataset --input $INPUT --outdir results --recombination gubbins --max_memory 600.GB"
    
elif [ "$GENOME_COUNT" -lt 300 ]; then
    echo "⚠ Large dataset ($GENOME_COUNT genomes)"
    echo "  Recommended profile: -profile google_vm_large (if available)"
    echo "  Recommended recombination: --recombination gubbins"
    echo "  Alternative: --recombination_method lightweight (if Gubbins fails)"
    echo ""
    echo "  Primary command:"
    echo "  nextflow run main.nf -profile google_vm_large --input $INPUT --outdir results --recombination gubbins --max_memory 1400.GB"
    echo ""
    echo "  Fallback command (if bus errors occur):"
    echo "  nextflow run main.nf -profile google_vm_large --input $INPUT --outdir results --recombination gubbins --recombination_method lightweight --max_memory 1400.GB"
    
else
    echo "⚠ Ultra-large dataset ($GENOME_COUNT genomes)"
    echo "  This dataset size may cause memory issues with standard Gubbins"
    echo "  Recommended approach: Use lightweight recombination method"
    echo ""
    echo "  Recommended command:"
    echo "  nextflow run main.nf -profile google_vm_large --input $INPUT --outdir results --recombination gubbins --recombination_method lightweight --max_memory 1400.GB"
    echo ""
    echo "  Note: The lightweight method skips actual recombination detection but allows the pipeline to complete"
    echo "        and produce phylogenetic trees and distance matrices."
fi

echo ""
echo "System Requirements:"
echo "==================="

if [ "$GENOME_COUNT" -lt 50 ]; then
    echo "  Minimum RAM: 32 GB"
    echo "  Recommended RAM: 64 GB"
    echo "  CPUs: 8-16"
elif [ "$GENOME_COUNT" -lt 200 ]; then
    echo "  Minimum RAM: 128 GB"
    echo "  Recommended RAM: 256 GB"
    echo "  CPUs: 16-32"
elif [ "$GENOME_COUNT" -lt 300 ]; then
    echo "  Minimum RAM: 512 GB"
    echo "  Recommended RAM: 1000+ GB"
    echo "  CPUs: 32-64"
else
    echo "  Minimum RAM: 1000+ GB"
    echo "  Recommended RAM: 1500+ GB"
    echo "  CPUs: 32-64"
    echo "  Note: Consider using lightweight method to avoid memory issues"
fi

echo ""
echo "Troubleshooting:"
echo "================"
echo "If you encounter bus errors (exit code 135/139):"
echo "1. Try reducing CPU count in the profile"
echo "2. Use --recombination_method lightweight"
echo "3. Increase --max_memory if possible"
echo "4. Consider splitting your dataset into smaller batches"