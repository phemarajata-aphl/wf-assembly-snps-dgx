# Running wf-assembly-snps on SLURM

## Quick Start

### Standard SLURM Cluster

1. **Set up environment variables:**
   ```bash
   export SLURM_ACCOUNT="your_account_name"
   export NXF_SINGULARITY_CACHEDIR="/path/to/singularity/cache"
   ```

2. **Run the pipeline:**
   ```bash
   nextflow run main.nf \
     -profile slurm \
     --input /path/to/your/assemblies \
     --outdir results \
     --snp_package parsnp
   ```

### NVIDIA DGX Station A100

1. **Set up environment variables:**
   ```bash
   export SLURM_ACCOUNT="your_account_name"
   export SLURM_PARTITION="dgx"
   export NXF_SINGULARITY_CACHEDIR="/raid/cache/singularity"
   export NXF_WORK="/raid/work"
   ```

2. **Run the pipeline with DGX optimization:**
   ```bash
   nextflow run main.nf \
     -profile dgx_a100 \
     --input /path/to/your/assemblies \
     --outdir results \
     --snp_package parsnp \
     -work-dir /raid/work
   ```

## Profile Configurations

### Standard SLURM Profile (`-profile slurm`)

- **Executor**: SLURM scheduler
- **Container system**: Singularity (recommended for HPC)
- **Resource allocation**: Standard HPC cluster resources
- **Error handling**: Automatic retry on failure (up to 2 times)

### DGX A100 Profile (`-profile dgx_a100`)

- **Executor**: SLURM scheduler optimized for DGX hardware
- **Container system**: Singularity with DGX-specific cache paths
- **Resource allocation**: Optimized for DGX A100 (128 CPUs, 1TB RAM)
- **Performance**: NUMA and threading optimizations
- **GPU support**: Ready for GPU-accelerated tools

## Resource Requirements

### Standard SLURM Profile

| Process Label | CPUs | Memory | Time |
|---------------|------|--------|------|
| process_single | 2 | 16 GB | 2h |
| process_low | 4 | 32 GB | 4h |
| process_medium | 16 | 128 GB | 8h |
| process_high | 32 | 256 GB | 12h |
| process_long | 8 | 64 GB | 24h |
| process_high_memory | 16 | 512 GB | 16h |

### DGX A100 Profile

| Process Label | CPUs | Memory | Time |
|---------------|------|--------|------|
| process_single | 4 | 32 GB | 2h |
| process_low | 8 | 64 GB | 4h |
| process_medium | 24 | 192 GB | 6h |
| process_high | 48 | 384 GB | 12h |
| process_long | 16 | 128 GB | 48h |
| process_high_memory | 32 | 768 GB | 16h |
| process_high_cpu | 96 | 512 GB | 8h |

## Environment Variables

- `SLURM_ACCOUNT`: Your SLURM account name (required)
- `NXF_SINGULARITY_CACHEDIR`: Directory for Singularity image cache

## Example Submission Scripts

- **Standard SLURM**: See `run_slurm_example.sh` for a general SLURM submission script
- **DGX A100**: See `run_dgx_a100_example.sh` for a DGX-optimized submission script

## DGX A100 Specific Optimizations

The DGX A100 profile includes several performance optimizations:

1. **Resource Scaling**: Takes advantage of the 128 CPU cores and 1TB RAM
2. **NUMA Optimization**: Proper thread and memory binding
3. **Fast Storage**: Utilizes `/raid` storage for work directories and caches
4. **Process-Specific Tuning**: Key processes like ParSNP get dedicated high-resource allocation
5. **GPU Readiness**: Prepared for future GPU-accelerated bioinformatics tools

### Key DGX A100 Features Used:
- **CPU**: Up to 96 cores for high-CPU processes
- **Memory**: Up to 768GB for memory-intensive processes  
- **Storage**: Fast NVMe RAID for work directories
- **Exclusive Access**: Option for exclusive node access for large jobs

## Troubleshooting

1. **Permission errors**: Fixed in this version by replacing `sed -i` commands
2. **Account not specified**: Make sure to set `SLURM_ACCOUNT` environment variable
3. **Singularity cache**: Ensure the cache directory exists and is writable

## Customization

To modify resource requirements, edit `conf/profiles/slurm.config`:

```groovy
process {
    withName: 'SPECIFIC_PROCESS_NAME' {
        cpus   = 8
        memory = 32.GB
        time   = 12.h
    }
}
```