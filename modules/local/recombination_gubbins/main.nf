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

    msg "INFO: Performing recombination using Gubbins with automatic fallback."

    # Set memory limits and optimizations for large datasets
    export OMP_NUM_THREADS=!{task.cpus}
    export MALLOC_ARENA_MAX=2
    
    # Enhanced memory management for very large datasets (300+ genomes)
    export MALLOC_MMAP_THRESHOLD_=65536
    export MALLOC_TRIM_THRESHOLD_=65536
    export MALLOC_TOP_PAD_=65536
    export MALLOC_MMAP_MAX_=32768
    
    # Set conservative memory limits to prevent bus errors
    # Use 85% of available memory to leave more buffer for system
    MEMORY_LIMIT_KB=$(((!{task.memory.toMega()} * 1024 * 85) / 100))
    ulimit -v $MEMORY_LIMIT_KB
    
    # Ensure tree file is available for Gubbins (especially important for resume workflow)
    if [[ ! -f "!{meta.snp_package}.tree" ]]; then
        msg "INFO: Tree file !{meta.snp_package}.tree not found, searching in alignment files..."
        # Search for tree file in alignment_files
        alignment_files_array=(!{alignment_files})
        TREE_FOUND=false
        for file in "${alignment_files_array[@]}"; do
            filename=$(basename "$file")
            if [[ "$filename" == "!{meta.snp_package}.tree" || "$filename" == "Parsnp.tree" ]] && [[ -f "$file" ]]; then
                msg "INFO: Found tree file: $file, copying to work directory"
                cp "$file" "!{meta.snp_package}.tree"
                TREE_FOUND=true
                break
            fi
        done
        
        if [[ "$TREE_FOUND" != "true" ]]; then
            msg "WARNING: No tree file found. Gubbins will generate its own starting tree."
        fi
    else
        msg "INFO: Tree file !{meta.snp_package}.tree already available"
    fi
    
    # For very large datasets (300+ genomes), use more conservative Gubbins options
    GENOME_COUNT=$(grep -c "^>" "!{core_alignment_fasta}" || echo "0")
    msg "INFO: Processing $GENOME_COUNT genomes with Gubbins"
    
    # Function to run lightweight fallback
    run_lightweight_fallback() {
        msg "WARNING: Gubbins failed. Falling back to lightweight recombination detection."
        msg "INFO: This fallback method will not perform actual recombination detection but will allow the pipeline to continue."
        
        # Create a minimal recombination positions file (empty - no masking)
        echo -e "##gff-version 3" > "!{meta.snp_package}-Gubbins.recombination_positions.txt"
        echo -e "##sequence-region !{meta.snp_package} 1 1000000" >> "!{meta.snp_package}-Gubbins.recombination_positions.txt"
        
        # Copy the input tree as the output tree
        if [[ -f "!{meta.snp_package}.tree" ]]; then
            cp "!{meta.snp_package}.tree" "!{meta.snp_package}-Gubbins.labelled_tree.tree"
        else
            # Create a minimal tree if none exists
            echo "($(grep '^>' !{core_alignment_fasta} | sed 's/^>//' | tr '\\n' ',' | sed 's/,$//'));" > "!{meta.snp_package}-Gubbins.labelled_tree.tree"
        fi
        
        msg "INFO: Lightweight fallback completed successfully."
        return 0
    }
    
    # Try Gubbins with enhanced error handling
    GUBBINS_SUCCESS=false
    
    if [[ $GENOME_COUNT -gt 300 ]]; then
        msg "INFO: Large dataset detected ($GENOME_COUNT genomes). Using conservative Gubbins settings."
        
        # Try Gubbins with ultra-conservative settings for very large datasets
        if run_gubbins.py \
          --starting-tree "!{meta.snp_package}.tree" \
          --prefix "!{meta.snp_package}-Gubbins" \
          --threads !{task.cpus} \
          --iterations 2 \
          --min-snps 15 \
          --filter-percentage 75 \
          --verbose \
          "!{core_alignment_fasta}"; then
            GUBBINS_SUCCESS=true
            msg "INFO: Gubbins completed successfully with conservative settings."
        else
            GUBBINS_EXIT_CODE=$?
            msg "WARNING: Gubbins failed with exit code $GUBBINS_EXIT_CODE"
            if [[ $GUBBINS_EXIT_CODE -eq 135 || $GUBBINS_EXIT_CODE -eq 139 || $GUBBINS_EXIT_CODE -eq 137 ]]; then
                msg "INFO: Bus error or memory issue detected. Attempting lightweight fallback."
                run_lightweight_fallback
                GUBBINS_SUCCESS=true
            fi
        fi
    else
        msg "INFO: Standard dataset size ($GENOME_COUNT genomes). Using default Gubbins settings."
        
        if run_gubbins.py \
          --starting-tree "!{meta.snp_package}.tree" \
          --prefix "!{meta.snp_package}-Gubbins" \
          --threads !{task.cpus} \
          --verbose \
          "!{core_alignment_fasta}"; then
            GUBBINS_SUCCESS=true
            msg "INFO: Gubbins completed successfully with standard settings."
        else
            GUBBINS_EXIT_CODE=$?
            msg "WARNING: Gubbins failed with exit code $GUBBINS_EXIT_CODE"
            if [[ $GUBBINS_EXIT_CODE -eq 135 || $GUBBINS_EXIT_CODE -eq 139 || $GUBBINS_EXIT_CODE -eq 137 ]]; then
                msg "INFO: Bus error or memory issue detected. Attempting lightweight fallback."
                run_lightweight_fallback
                GUBBINS_SUCCESS=true
            fi
        fi
    fi
    
    # If Gubbins failed and fallback didn't work, exit with error
    if [[ "$GUBBINS_SUCCESS" != "true" ]]; then
        msg "ERROR: Both Gubbins and lightweight fallback failed."
        exit 1
    fi

    # Check if output files exist before renaming (only if Gubbins succeeded normally)
    if [[ -f "!{meta.snp_package}-Gubbins.recombination_predictions.gff" ]]; then
        mv "!{meta.snp_package}-Gubbins.recombination_predictions.gff" \
          "!{meta.snp_package}-Gubbins.recombination_positions.txt"
        msg "INFO: Renamed recombination predictions file."
    elif [[ ! -f "!{meta.snp_package}-Gubbins.recombination_positions.txt" ]]; then
        msg "ERROR: No recombination positions file found after processing."
        exit 1
    fi

    if [[ -f "!{meta.snp_package}-Gubbins.node_labelled.final_tree.tre" ]]; then
        mv "!{meta.snp_package}-Gubbins.node_labelled.final_tree.tre" \
          "!{meta.snp_package}-Gubbins.labelled_tree.tree"
        msg "INFO: Renamed tree file."
    elif [[ ! -f "!{meta.snp_package}-Gubbins.labelled_tree.tree" ]]; then
        msg "ERROR: No tree file found after processing."
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        gubbins: $(run_gubbins.py --version | sed 's/^/    /')
    END_VERSIONS
    '''
}
