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
    export MALLOC_ARENA_MAX=4
    
    # Use ulimit to prevent memory issues
    ulimit -v $((!{task.memory.toMega()} * 1024))

    run_gubbins.py \
      --starting-tree "!{meta.snp_package}.tree" \
      --prefix "!{meta.snp_package}-Gubbins" \
      --threads !{task.cpus} \
      --verbose \
      "!{core_alignment_fasta}"

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
