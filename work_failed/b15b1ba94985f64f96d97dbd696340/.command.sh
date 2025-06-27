#!/bin/bash -euo pipefail
source bash_functions.sh

msg "INFO: Performing recombination using Gubbins."

# Set memory limits and optimizations for large datasets
export OMP_NUM_THREADS=64
export MALLOC_ARENA_MAX=4

# Set memory-related environment variables for better memory management
export MALLOC_MMAP_THRESHOLD_=131072
export MALLOC_TRIM_THRESHOLD_=131072
export MALLOC_TOP_PAD_=131072
export MALLOC_MMAP_MAX_=65536

# Don't set ulimit -v as it can cause bus errors with large datasets
# ulimit -v $((491520 * 1024))

run_gubbins.py       --starting-tree "Parsnp.tree"       --prefix "Parsnp-Gubbins"       --threads 64       --verbose       "Parsnp.Core_Alignment.fasta"

# Check if output files exist before renaming
if [[ -f "Parsnp-Gubbins.recombination_predictions.gff" ]]; then
    mv "Parsnp-Gubbins.recombination_predictions.gff"           "Parsnp-Gubbins.recombination_positions.txt"
else
    msg "ERROR: Gubbins recombination predictions file not found"
    exit 1
fi

if [[ -f "Parsnp-Gubbins.node_labelled.final_tree.tre" ]]; then
    mv "Parsnp-Gubbins.node_labelled.final_tree.tre"           "Parsnp-Gubbins.labelled_tree.tree"
else
    msg "ERROR: Gubbins tree file not found"
    exit 1
fi

cat <<-END_VERSIONS > versions.yml
"ASSEMBLY_SNPS:ASSEMBLY_SNPS_RESUME:RECOMBINATION:RECOMBINATION_GUBBINS":
    gubbins: $(run_gubbins.py --version | sed 's/^/    /')
END_VERSIONS
