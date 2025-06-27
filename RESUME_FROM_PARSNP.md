# Resume Workflow from Existing ParSNP Outputs

This modification allows you to resume the wf-assembly-snps pipeline from the Gubbins step using existing ParSNP output files, bypassing the time-consuming ParSNP computation.

**IMPORTANT**: You must first copy your ParSNP output files from the work directory to a dedicated directory before running the pipeline.

## When to Use This Feature

- When ParSNP has completed successfully but the pipeline failed at a later step (e.g., Gubbins)
- When you want to re-run only the recombination detection and downstream analysis
- When you have fixed memory issues for Gubbins but don't want to re-run ParSNP

## Required Files

The pipeline expects these ParSNP output files in the specified directory:
- `Parsnp.ggr` (Gingr binary file)
- `Parsnp.SNP_Distances_Matrix.tsv` (Distance matrix)
- `Parsnp.SNPs.fa.gz` (SNP alignment)
- `Parsnp.tree` (Phylogenetic tree)
- `Parsnp.xmfa` (Multi-FASTA alignment)
- `versions.yml` (Software versions)

## Step-by-Step Instructions

### 1. Copy ParSNP Output Files

Use the provided script to copy files from your work directory:

```bash
./copy_parsnp_outputs.sh /home/cdcadmin/wf-assembly-snps/work/bf/5ff40d9bddcc203d095c44320909b1 ./parsnp_outputs
```

Or manually copy the files:

```bash
mkdir -p parsnp_outputs
cp /home/cdcadmin/wf-assembly-snps/work/bf/5ff40d9bddcc203d095c44320909b1/Parsnp.* ./parsnp_outputs/
cp /home/cdcadmin/wf-assembly-snps/work/bf/5ff40d9bddcc203d095c44320909b1/versions.yml ./parsnp_outputs/
```

### 2. Run the Pipeline with Existing Outputs

```bash
nextflow run main.nf \
  -profile large_dataset \
  --input <your_original_input_dir> \
  --outdir <your_output_dir> \
  --parsnp_outputs ./parsnp_outputs \
  --snp_package parsnp \
  --max_memory 600.GB
```

## What This Does

When you specify `--parsnp_outputs`, the pipeline will:

1. **Skip input preprocessing** - No need to validate and process input genome files
2. **Skip ParSNP computation** - Uses your existing ParSNP output files
3. **Skip distance calculation** - Uses the existing distance matrix from ParSNP
4. **Start from Gingr conversion** - Begins with the CONVERT_GINGR_TO_FASTA_HARVESTTOOLS step
5. **Continue normally** - Runs recombination detection (Gubbins), masking, and tree building

## Important Notes

- You still need to provide the original `--input` parameter (the pipeline needs this for metadata)
- The `--parsnp_outputs` directory should contain all the required ParSNP output files
- This modification preserves all existing functionality - if you don't use `--parsnp_outputs`, the pipeline runs normally
- The pipeline will log that it's using existing ParSNP outputs when this option is enabled

## Troubleshooting

### 1. Verify ParSNP Output Files
Use the test script to verify all required files are present:

```bash
./test_parsnp_outputs.sh ./parsnp_outputs
```

Or manually check:
```bash
ls -la parsnp_outputs/
# Should show: Parsnp.ggr, Parsnp.SNP_Distances_Matrix.tsv, Parsnp.SNPs.fa.gz, Parsnp.tree, Parsnp.xmfa, versions.yml
```

### 2. Check Pipeline Logs
The pipeline will log key parameters at startup. Look for:
```
=== WORKFLOW PARAMETERS ===
Input: /path/to/input
Output directory: /path/to/output
ParSNP outputs: ./parsnp_outputs
SNP package: parsnp
Recombination: gubbins
===========================
```

### 3. Common Issues
- **Pipeline still starts from beginning**: Ensure `--parsnp_outputs` parameter is correctly specified
- **Missing files error**: All 6 required ParSNP output files must be present
- **Path issues**: Use absolute paths or ensure relative paths are correct from where you run the pipeline

## Example Complete Command

```bash
# Copy the files
./copy_parsnp_outputs.sh /home/cdcadmin/wf-assembly-snps/work/bf/5ff40d9bddcc203d095c44320909b1 ./parsnp_outputs

# Run the pipeline starting from Gubbins
nextflow run main.nf \
  -profile large_dataset \
  --input /path/to/your/genomes \
  --outdir results_resumed \
  --parsnp_outputs ./parsnp_outputs \
  --snp_package parsnp \
  --max_memory 600.GB \
  --recombination gubbins
```