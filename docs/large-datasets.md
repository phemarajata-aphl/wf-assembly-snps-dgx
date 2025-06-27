# Handling Large Datasets (200+ Genomes)

## Overview

When working with large datasets (200+ genomes), the pipeline requires significantly more computational resources, especially for the recombination detection step using Gubbins. This guide provides optimized configurations and troubleshooting tips.

## Quick Start for Large Datasets

Use the `large_dataset` profile specifically designed for datasets with 200+ genomes:

```bash
nextflow run main.nf \
  -profile large_dataset \
  --input /path/to/your/assemblies \
  --outdir results \
  --snp_package parsnp \
  --max_memory 600.GB \
  --max_cpus 32
```

## Resource Requirements

### Minimum System Requirements for 300+ Genomes:
- **Memory**: 600GB+ RAM
- **CPUs**: 16+ cores
- **Storage**: 500GB+ free space
- **Time**: 48-96 hours

### Process-Specific Requirements:

| Process | CPUs | Memory | Time | Notes |
|---------|------|--------|------|-------|
| ParSNP Alignment | 24 | 300GB | 48h | Scales with genome count |
| Gubbins Recombination | 16 | 600GB | 96h | Most memory-intensive |
| Tree Building | 20 | 200GB | 72h | CPU-intensive |
| Distance Calculation | 8 | 64GB | 4h | Relatively fast |

## Common Issues and Solutions

### 1. Bus Error (Exit Status 135)
**Cause**: Insufficient memory for Gubbins
**Solution**: 
```bash
# Use large_dataset profile
nextflow run main.nf -profile large_dataset --max_memory 800.GB

# Or increase memory manually
nextflow run main.nf --max_memory 1000.GB
```

### 2. Out of Memory Errors
**Cause**: System running out of RAM
**Solutions**:
- Use the `large_dataset` profile
- Increase swap space
- Run on a high-memory system
- Consider reducing dataset size

### 3. Process Timeout
**Cause**: Processes taking longer than expected
**Solution**:
```bash
nextflow run main.nf -profile large_dataset --max_time 168.h
```

### 4. Disk Space Issues
**Cause**: Large intermediate files
**Solutions**:
- Use fast, high-capacity storage
- Set work directory to high-capacity drive:
```bash
nextflow run main.nf -work-dir /path/to/large/storage
```

## Performance Optimization Tips

### 1. System Configuration
```bash
# Increase system limits
ulimit -v unlimited
ulimit -m unlimited

# Set environment variables
export OMP_NUM_THREADS=16
export MALLOC_ARENA_MAX=4
```

### 2. Docker/Singularity Settings
```bash
# For Docker
export DOCKER_OPTS="--memory=600g --cpus=32"

# For Singularity
export SINGULARITY_CACHEDIR="/path/to/fast/storage"
```

### 3. Nextflow Configuration
```bash
# Use resume to restart from checkpoints
nextflow run main.nf -profile large_dataset -resume

# Generate execution reports
nextflow run main.nf -profile large_dataset \
  -with-report execution_report.html \
  -with-timeline execution_timeline.html
```

## Expected Runtimes

### Dataset Size vs Runtime (approximate):
- **50 genomes**: 4-8 hours
- **100 genomes**: 8-16 hours
- **200 genomes**: 24-48 hours
- **300+ genomes**: 48-96 hours

### Bottleneck Processes:
1. **Gubbins**: 60-80% of total runtime
2. **ParSNP**: 15-25% of total runtime
3. **Tree Building**: 5-10% of total runtime

## Monitoring and Troubleshooting

### 1. Monitor Resource Usage
```bash
# Check memory usage
free -h

# Check CPU usage
htop

# Check disk usage
df -h
```

### 2. Nextflow Monitoring
```bash
# Check pipeline status
nextflow log

# View specific process logs
nextflow log [run_name] -f process,exit,memory,time
```

### 3. Process-Specific Logs
```bash
# Check Gubbins logs
cat work/[hash]/[gubbins_work_dir]/.command.out
cat work/[hash]/[gubbins_work_dir]/.command.err
```

## Alternative Approaches for Very Large Datasets

### 1. Subset Analysis
For datasets >500 genomes, consider:
- Random sampling of representative genomes
- Hierarchical clustering approach
- Core genome vs accessory genome analysis

### 2. High-Performance Computing
- Use HPC clusters with job schedulers (SLURM, PBS)
- Utilize high-memory nodes (1TB+ RAM)
- Consider distributed computing approaches

### 3. Alternative Tools
For extremely large datasets, consider:
- FastTree instead of RAxML for phylogeny
- Simplified recombination detection
- Core SNP-only analysis

## Configuration Examples

### High-Memory System (1TB RAM)
```groovy
process {
    withName: 'ASSEMBLY_SNPS:RECOMBINATION:RECOMBINATION_GUBBINS' {
        memory = '800.GB'
        cpus = 32
        time = '120.h'
    }
}
```

### HPC Cluster
```groovy
process {
    executor = 'slurm'
    queue = 'highmem'
    clusterOptions = '--mem=600G --time=96:00:00'
}
```

## Support

If you continue to experience issues with large datasets:
1. Check system resources and requirements
2. Review the execution reports for bottlenecks
3. Consider the alternative approaches mentioned above
4. Contact the pipeline maintainers with specific error logs