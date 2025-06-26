#!/bin/bash
#SBATCH --job-name=wf-assembly-snps
#SBATCH --account=YOUR_ACCOUNT_HERE
#SBATCH --partition=YOUR_PARTITION_HERE
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=nextflow_%j.out
#SBATCH --error=nextflow_%j.err

# Load required modules (adjust for your system)
# module load nextflow
# module load singularity

# Set environment variables
export SLURM_ACCOUNT="YOUR_ACCOUNT_HERE"
export NXF_SINGULARITY_CACHEDIR="/path/to/your/singularity/cache"

# Run the pipeline
nextflow run main.nf \
  -profile slurm \
  --input /path/to/your/input/directory \
  --outdir results \
  --snp_package parsnp \
  -resume

echo "Pipeline completed at $(date)"