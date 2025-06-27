process RECOMBINATION_GUBBINS {

    tag { "${meta.snp_package}" }
    label "process_high_memory"
    container "snads/gubbins@sha256:391a980312096f96d976f4be668d4dea7dda13115db004a50e49762accc0ec62"

    input:
    tuple val(meta), path(core_alignment_fasta)
    tuple val(meta_alignment), path(alignment_files)

    output:
    tuple val(meta), path("*.{txt,tree}"), emit: positions_and_tree
    path(".command.{out,err}")
    path("versions.yml")                 , emit: versions

    shell:
    '''
    source bash_functions.sh

    msg "INFO: Performing recombination using Gubbins."

    # Set memory limits and optimizations for large datasets
    export OMP_NUM_THREADS=!{task.cpus}
    export MALLOC_ARENA_MAX=2
    
    # Enhanced memory management for very large datasets (300+ genomes)
    export MALLOC_MMAP_THRESHOLD_=65536
    export MALLOC_TRIM_THRESHOLD_=65536
    export MALLOC_TOP_PAD_=65536
    export MALLOC_MMAP_MAX_=32768
    
    # Set conservative memory limits to prevent bus errors
    # Use 90% of available memory to leave buffer for system
    MEMORY_LIMIT_KB=$(((!{task.memory.toMega()} * 1024 * 90) / 100))
    ulimit -v $MEMORY_LIMIT_KB
    
    # For very large datasets (300+ genomes), use more conservative Gubbins options
    GENOME_COUNT=$(grep -c "^>" "!{core_alignment_fasta}" || echo "0")
    msg "INFO: Processing $GENOME_COUNT genomes with Gubbins"
    
    if [[ $GENOME_COUNT -gt 300 ]]; then
        msg "INFO: Large dataset detected ($GENOME_COUNT genomes). Using conservative Gubbins settings."
        run_gubbins.py \
          --starting-tree "!{meta.snp_package}.tree" \
          --prefix "!{meta.snp_package}-Gubbins" \
          --threads !{task.cpus} \
          --iterations 3 \
          --min-snps-for-recombination 10 \
          --filter-percentage 50 \
          --verbose \
          "!{core_alignment_fasta}"
    else
        msg "INFO: Standard dataset size ($GENOME_COUNT genomes). Using default Gubbins settings."
        run_gubbins.py \
          --starting-tree "!{meta.snp_package}.tree" \
          --prefix "!{meta.snp_package}-Gubbins" \
          --threads !{task.cpus} \
          --verbose \
          "!{core_alignment_fasta}"
    fi

    # Check if output files exist before renaming
    if [[ -f "!{meta.snp_package}-Gubbins.recombination_predictions.gff" ]]; then
        mv "!{meta.snp_package}-Gubbins.recombination_predictions.gff" \
          "!{meta.snp_package}-Gubbins.recombination_positions.txt"
    else
        msg "ERROR: Gubbins recombination predictions file not found"
        exit 1
    fi

    if [[ -f "!{meta.snp_package}-Gubbins.node_labelled.final_tree.tre" ]]; then
        mv "!{meta.snp_package}-Gubbins.node_labelled.final_tree.tre" \
          "!{meta.snp_package}-Gubbins.labelled_tree.tree"
    else
        msg "ERROR: Gubbins tree file not found"
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        gubbins: $(run_gubbins.py --version | sed 's/^/    /')
    END_VERSIONS
    '''
}
