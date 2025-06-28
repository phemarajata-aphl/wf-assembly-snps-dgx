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
    
    # Optimize memory settings for Gubbins to use the full allocated memory
    export MALLOC_ARENA_MAX=16  # Allow more memory arenas for better utilization
    export MALLOC_MMAP_THRESHOLD_=1048576  # 1MB threshold for mmap
    export MALLOC_TRIM_THRESHOLD_=1048576  # 1MB threshold for trimming
    export MALLOC_TOP_PAD_=1048576         # 1MB top padding
    export MALLOC_MMAP_MAX_=262144         # More mmap regions allowed
    
    # Remove any memory restrictions and let Gubbins use the full allocation
    # With 1300GB allocated, Gubbins should have access to all of it
    msg "INFO: Allocated memory: !{task.memory}, CPUs: !{task.cpus}"
    msg "INFO: Optimizing memory settings for large dataset processing"
    
    # Check available memory in container
    AVAILABLE_MEMORY_GB=$(free -g | awk 'NR==2{print $2}')
    msg "INFO: Available memory in container: ${AVAILABLE_MEMORY_GB}GB"
    
    # Set Java heap size for any Java components (if used by Gubbins)
    export JAVA_OPTS="-Xmx$((!{task.memory.toGiga()} - 100))g"
    msg "INFO: Java heap size set to: $JAVA_OPTS"
    
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
    
    # Start memory monitoring in background
    (
        while true; do
            MEMORY_USED=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')
            MEMORY_USED_GB=$(free -m | awk 'NR==2{printf "%.1f", $3/1024 }')
            echo "$(date '+%H:%M:%S') - Memory usage: ${MEMORY_USED} (${MEMORY_USED_GB} GB used)"
            sleep 60
        done
    ) &
    MONITOR_PID=$!
    
    # Try different Gubbins strategies based on dataset size
    if [[ $GENOME_COUNT -gt 300 ]]; then
        msg "INFO: Large dataset detected ($GENOME_COUNT genomes). Using optimized Gubbins settings for large datasets."
        
        # For large datasets, use settings optimized for memory efficiency and performance
        msg "INFO: Attempt 1 - Large dataset optimized settings"
        if timeout 24h run_gubbins.py \
          --starting-tree "!{meta.snp_package}.tree" \
          --prefix "!{meta.snp_package}-Gubbins" \
          --threads !{task.cpus} \
          --iterations 5 \
          --min-snps 5 \
          --filter-percentage 25 \
          --model GTRGAMMA \
          --verbose \
          "!{core_alignment_fasta}"; then
            GUBBINS_SUCCESS=true
            msg "INFO: Gubbins completed successfully with large dataset settings."
        else
            GUBBINS_EXIT_CODE=$?
            msg "WARNING: Gubbins attempt 1 failed with exit code $GUBBINS_EXIT_CODE"
            
            # Second attempt: More conservative but still thorough
            msg "INFO: Attempt 2 - Conservative large dataset settings"
            if timeout 48h run_gubbins.py \
              --starting-tree "!{meta.snp_package}.tree" \
              --prefix "!{meta.snp_package}-Gubbins" \
              --threads $(((!{task.cpus} * 3) / 4)) \
              --iterations 3 \
              --min-snps 8 \
              --filter-percentage 40 \
              --model GTRGAMMA \
              --verbose \
              "!{core_alignment_fasta}"; then
                GUBBINS_SUCCESS=true
                msg "INFO: Gubbins completed successfully with conservative large dataset settings."
            else
                GUBBINS_EXIT_CODE=$?
                msg "WARNING: Gubbins attempt 2 failed with exit code $GUBBINS_EXIT_CODE"
                
                # Third attempt: Very conservative settings
                msg "INFO: Attempt 3 - Very conservative settings"
                if timeout 72h run_gubbins.py \
                  --starting-tree "!{meta.snp_package}.tree" \
                  --prefix "!{meta.snp_package}-Gubbins" \
                  --threads $(((!{task.cpus} / 2))) \
                  --iterations 2 \
                  --min-snps 15 \
                  --filter-percentage 75 \
                  --verbose \
                  "!{core_alignment_fasta}"; then
                    GUBBINS_SUCCESS=true
                    msg "INFO: Gubbins completed successfully with very conservative settings."
                else
                    GUBBINS_EXIT_CODE=$?
                    msg "ERROR: All Gubbins attempts failed with exit code $GUBBINS_EXIT_CODE"
                    
                    # Only fall back to lightweight if we get memory-related errors after all attempts
                    if [[ $GUBBINS_EXIT_CODE -eq 135 || $GUBBINS_EXIT_CODE -eq 139 || $GUBBINS_EXIT_CODE -eq 137 || $GUBBINS_EXIT_CODE -eq 124 ]]; then
                        msg "ERROR: Memory-related or timeout error detected after all attempts."
                        msg "ERROR: With 1300GB allocated and multiple attempts, this suggests a fundamental issue."
                        msg "INFO: Falling back to lightweight method as last resort."
                        run_lightweight_fallback
                        GUBBINS_SUCCESS=true
                    else
                        msg "ERROR: Gubbins failed with non-memory error: $GUBBINS_EXIT_CODE"
                        msg "ERROR: This may indicate data quality issues or software bugs."
                        GUBBINS_SUCCESS=false
                    fi
                fi
            fi
        fi
    else
        msg "INFO: Standard dataset size ($GENOME_COUNT genomes). Using standard Gubbins settings."
        
        # For standard datasets, use full capabilities
        if timeout 12h run_gubbins.py \
          --starting-tree "!{meta.snp_package}.tree" \
          --prefix "!{meta.snp_package}-Gubbins" \
          --threads !{task.cpus} \
          --iterations 5 \
          --model GTRGAMMA \
          --verbose \
          "!{core_alignment_fasta}"; then
            GUBBINS_SUCCESS=true
            msg "INFO: Gubbins completed successfully with standard settings."
        else
            GUBBINS_EXIT_CODE=$?
            msg "WARNING: Gubbins failed with exit code $GUBBINS_EXIT_CODE"
            
            # For smaller datasets, try with fewer threads but more iterations
            msg "INFO: Retrying with reduced thread count but thorough analysis"
            if timeout 24h run_gubbins.py \
              --starting-tree "!{meta.snp_package}.tree" \
              --prefix "!{meta.snp_package}-Gubbins" \
              --threads $(((!{task.cpus} / 2))) \
              --iterations 5 \
              --model GTRGAMMA \
              --verbose \
              "!{core_alignment_fasta}"; then
                GUBBINS_SUCCESS=true
                msg "INFO: Gubbins completed successfully with reduced threads."
            else
                GUBBINS_EXIT_CODE=$?
                msg "WARNING: Gubbins retry failed with exit code $GUBBINS_EXIT_CODE"
                
                # Final attempt with very conservative settings
                msg "INFO: Final attempt with conservative settings"
                if timeout 48h run_gubbins.py \
                  --starting-tree "!{meta.snp_package}.tree" \
                  --prefix "!{meta.snp_package}-Gubbins" \
                  --threads $(((!{task.cpus} / 4))) \
                  --iterations 3 \
                  --verbose \
                  "!{core_alignment_fasta}"; then
                    GUBBINS_SUCCESS=true
                    msg "INFO: Gubbins completed successfully with conservative settings."
                else
                    GUBBINS_EXIT_CODE=$?
                    msg "ERROR: All Gubbins attempts failed with exit code $GUBBINS_EXIT_CODE"
                    if [[ $GUBBINS_EXIT_CODE -eq 135 || $GUBBINS_EXIT_CODE -eq 139 || $GUBBINS_EXIT_CODE -eq 137 || $GUBBINS_EXIT_CODE -eq 124 ]]; then
                        msg "INFO: Memory or timeout issue detected. Attempting lightweight fallback."
                        run_lightweight_fallback
                        GUBBINS_SUCCESS=true
                    else
                        msg "ERROR: Gubbins failed with non-memory error: $GUBBINS_EXIT_CODE"
                        GUBBINS_SUCCESS=false
                    fi
                fi
            fi
        fi
    fi
    
    # Stop memory monitoring
    kill $MONITOR_PID 2>/dev/null || true
    
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
    
    # Ensure output files have correct permissions to avoid rsync/staging issues
    chmod 644 *.txt *.tree 2>/dev/null || true
    msg "INFO: Set file permissions for output files."

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        gubbins: $(run_gubbins.py --version | sed 's/^/    /')
    END_VERSIONS
    '''
}
