process RECOMBINATION_CLONALFRAMEML {

    tag { "${meta.snp_package}" }
    label "process_medium"
    container "snads/clonalframeml@sha256:bc00db247195fdc6151793712a74cc9b272dc2c9f153bb0037415e387f15351e"

    input:
    tuple val(meta), path(core_alignment_fasta)
    tuple val(meta_alignment), path(alignment_files)

    output:
    tuple val(meta), path("*.{txt,tree}"), emit: positions_and_tree
    path(".command.{out,err}")
    path("versions.yml")                         , emit: versions

    shell:
    '''
    source bash_functions.sh

    msg "INFO: Performing recombination using ClonalFrameML."

    # Find and prepare the tree file for ClonalFrameML
    TREE_FILE=""
    
    # First, list all available files for debugging
    msg "INFO: Available files in work directory:"
    ls -la
    msg "INFO: Alignment files parameter: !{alignment_files}"
    
    # Method 1: Look for the expected tree file name directly
    if [[ -f "!{meta.snp_package}.tree" ]]; then
        TREE_FILE="!{meta.snp_package}.tree"
        msg "INFO: Found expected tree file: $TREE_FILE"
    fi
    
    # Method 2: Look for any .tree files in the current directory
    if [[ -z "$TREE_FILE" ]]; then
        for file in *.tree; do
            if [[ -f "$file" ]]; then
                TREE_FILE="$file"
                msg "INFO: Found tree file in current directory: $TREE_FILE"
                break
            fi
        done
    fi
    
    # Method 3: Search through the alignment_files parameter and copy if found
    if [[ -z "$TREE_FILE" ]]; then
        # Convert the alignment_files space-separated string to an array
        alignment_files_array=(!{alignment_files})
        for file in "${alignment_files_array[@]}"; do
            if [[ "$file" == *".tree" && -f "$file" ]]; then
                TREE_FILE="$file"
                msg "INFO: Found tree file in alignment_files: $TREE_FILE"
                # Copy it to the expected location
                cp "$TREE_FILE" "!{meta.snp_package}.tree"
                TREE_FILE="!{meta.snp_package}.tree"
                break
            fi
        done
    fi
    
    # Method 4: Try to find tree file by looking for common ParSNP tree file names
    if [[ -z "$TREE_FILE" ]]; then
        alignment_files_array=(!{alignment_files})
        for file in "${alignment_files_array[@]}"; do
            filename=$(basename "$file")
            if [[ "$filename" == "Parsnp.tree" && -f "$file" ]]; then
                msg "INFO: Found Parsnp.tree file: $file"
                cp "$file" "!{meta.snp_package}.tree"
                TREE_FILE="!{meta.snp_package}.tree"
                break
            fi
        done
    fi

    # Check if tree file was found
    if [[ -z "$TREE_FILE" ]]; then
        msg "ERROR: No tree file found for ClonalFrameML"
        msg "Available files in current directory:"
        ls -la
        msg "Alignment files parameter: !{alignment_files}"
        msg "Searched for files ending in .tree and specifically for Parsnp.tree"
        exit 1
    fi

    msg "INFO: Using tree file: $TREE_FILE"

    # Ensure the tree file is in the expected location
    if [[ "$TREE_FILE" != "!{meta.snp_package}.tree" ]]; then
        cp "$TREE_FILE" "!{meta.snp_package}.tree"
        msg "INFO: Copied tree file to expected location: !{meta.snp_package}.tree"
    fi

    # ClonalFrameML needs tree labels to not be surrounded by single quotes
    sed "s/'//g" "!{meta.snp_package}.tree" > temp_tree.tree
    mv temp_tree.tree "!{meta.snp_package}.tree"

    msg "INFO: Running ClonalFrameML with tree: !{meta.snp_package}.tree and alignment: !{core_alignment_fasta}"

    ClonalFrameML \
      "!{meta.snp_package}.tree" \
      "!{core_alignment_fasta}" \
      "!{meta.snp_package}-ClonalFrameML"

    # Rename output file
    mv \
      "!{meta.snp_package}-ClonalFrameML.importation_status.txt" \
      "!{meta.snp_package}-ClonalFrameML.recombination_positions.txt"

    mv \
      "!{meta.snp_package}-ClonalFrameML.labelled_tree.newick" \
      "!{meta.snp_package}-ClonalFrameML.labelled_tree.tree"

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        clonalframeml: $(ClonalFrameML -version | sed 's/^/    /')
    END_VERSIONS
    '''
}
