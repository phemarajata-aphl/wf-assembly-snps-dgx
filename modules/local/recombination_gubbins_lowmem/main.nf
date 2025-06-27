process RECOMBINATION_GUBBINS_LOWMEM {

    tag { "${meta.snp_package}" }
    label 'process_high_memory'

    conda "bioconda::gubbins=3.3.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gubbins:3.3.5--py312h30d9df9_0' :
        'biocontainers/gubbins:3.3.5--py312h30d9df9_0' }"

    input:
    tuple val(meta), path(core_alignment_fasta)
    tuple val(meta), path(alignment_files)

    output:
    tuple val(meta), path("*.recombination_predictions.gff"), emit: recombinants
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # Set memory limits and optimizations for large datasets
    export OMP_NUM_THREADS=${task.cpus}
    export MALLOC_ARENA_MAX=2
    
    # Set memory-related environment variables for better memory management
    export MALLOC_MMAP_THRESHOLD_=65536
    export MALLOC_TRIM_THRESHOLD_=65536
    export MALLOC_TOP_PAD_=65536
    export MALLOC_MMAP_MAX_=32768
    
    # Use memory-efficient options for Gubbins
    run_gubbins.py \\
      --starting-tree "${meta.snp_package}.tree" \\
      --prefix "${meta.snp_package}-Gubbins" \\
      --threads ${task.cpus} \\
      --verbose \\
      --no-cleanup \\
      --model GTRGAMMA \\
      --iterations 3 \\
      --min-snps 3 \\
      --filter-percentage 25 \\
      "${core_alignment_fasta}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gubbins: \$(run_gubbins.py --version | sed 's/^/    /')
    END_VERSIONS
    """
}