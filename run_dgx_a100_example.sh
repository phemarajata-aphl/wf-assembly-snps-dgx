#!/bin/bash
#SBATCH --job-name=wf-assembly-snps-dgx
#SBATCH --account=YOUR_ACCOUNT_HERE
#SBATCH --partition=dgx
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=nextflow_dgx_%j.out
#SBATCH --error=nextflow_dgx_%j.err
#SBATCH --exclusive

# DGX A100 optimized submission script for wf-assembly-snps

echo "Starting pipeline on DGX A100 at $(date)"
echo "SLURM Job ID: $SLURM_JOB_ID"
echo "Running on node: $SLURMD_NODENAME"

# Load required modules (adjust for your DGX system)
# module load nextflow/23.04.0
# module load singularity/3.8.0

# Set environment variables for DGX A100
export SLURM_ACCOUNT="YOUR_ACCOUNT_HERE"
export SLURM_PARTITION="dgx"
export NXF_SINGULARITY_CACHEDIR="/raid/cache/singularity"
export NXF_WORK="/raid/work"

# Performance optimizations for DGX
export OMP_NUM_THREADS=8
export MKL_NUM_THREADS=8
export OPENBLAS_NUM_THREADS=8
export MALLOC_ARENA_MAX=4

# NUMA optimizations (adjust based on your data location)
# numactl --cpunodebind=0 --membind=0 \

# Run the pipeline with DGX A100 optimized profile
nextflow run main.nf \
  -profile dgx_a100 \
  --input /path/to/your/input/directory \
  --outdir results \
  --snp_package parsnp \
  -work-dir /raid/work \
  -resume \
  -with-report results/execution_report.html \
  -with-timeline results/execution_timeline.html \
  -with-trace results/execution_trace.txt \
  -with-dag results/pipeline_dag.html

echo "Pipeline completed at $(date)"

# Optional: Clean up work directory after successful completion
# if [ $? -eq 0 ]; then
#     echo "Cleaning up work directory..."
#     rm -rf /raid/work/
# fi