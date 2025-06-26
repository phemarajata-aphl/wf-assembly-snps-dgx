# DGX A100 Performance Optimization Guide

## Hardware Overview
- **CPU**: 2x AMD EPYC 7742 (128 cores total)
- **Memory**: 1TB DDR4 RAM
- **GPU**: 8x NVIDIA A100 40GB
- **Storage**: High-speed NVMe RAID arrays
- **Network**: High-bandwidth InfiniBand

## Optimized Pipeline Execution

### 1. Use the DGX A100 Profile
```bash
nextflow run main.nf -profile dgx_a100 --input data/ --outdir results/
```

### 2. Optimal Storage Configuration
```bash
# Use fast RAID storage for work directory
export NXF_WORK="/raid/work"

# Use RAID for Singularity cache
export NXF_SINGULARITY_CACHEDIR="/raid/cache/singularity"
```

### 3. Memory and CPU Optimization
The DGX profile automatically sets:
- `OMP_NUM_THREADS`: Matches allocated CPUs
- `MKL_NUM_THREADS`: Optimized for Intel MKL
- `MALLOC_ARENA_MAX=4`: Reduces memory fragmentation

### 4. Process-Specific Optimizations

#### ParSNP Core Genome Alignment
- **Resources**: 48 CPUs, 256GB RAM
- **Time**: 4 hours
- **Special**: Exclusive node access for large datasets

#### Recombination Detection
- **Resources**: 32 CPUs, 128GB RAM  
- **Time**: 8 hours
- **Optimization**: High memory allocation for ClonalFrameML

#### Phylogenetic Tree Building
- **Resources**: 40 CPUs, 192GB RAM
- **Time**: 6 hours
- **Optimization**: Balanced CPU/memory for tree inference

## Performance Tips

### 1. Data Staging
```bash
# Stage input data on fast storage
cp -r /slow/storage/data /raid/staging/
nextflow run main.nf --input /raid/staging/data
```

### 2. Parallel Processing
The pipeline automatically scales based on:
- Number of input genomes
- Available resources
- Process requirements

### 3. Resource Monitoring
```bash
# Monitor resource usage
squeue -u $USER
scontrol show job $SLURM_JOB_ID
```

### 4. Cache Management
```bash
# Pre-pull containers
nextflow pull bacterial-genomics/wf-assembly-snps

# Clean cache periodically
nextflow clean -f
```

## Expected Performance

### Typical Runtimes (100 genomes)
- **Input Processing**: 5-10 minutes
- **Core Alignment**: 2-4 hours
- **Recombination**: 4-8 hours  
- **Distance Calculation**: 30 minutes
- **Tree Building**: 2-4 hours
- **Total**: 8-16 hours

### Scaling Characteristics
- **10 genomes**: ~2 hours
- **50 genomes**: ~6 hours
- **100 genomes**: ~12 hours
- **500 genomes**: ~24-48 hours

## Troubleshooting

### Memory Issues
If you encounter memory errors:
```bash
# Increase memory for specific processes
nextflow run main.nf -profile dgx_a100 \
  --max_memory 800.GB
```

### CPU Bottlenecks
For CPU-intensive steps:
```bash
# Use high-CPU configuration
nextflow run main.nf -profile dgx_a100 \
  --max_cpus 120
```

### Storage Issues
For large datasets:
```bash
# Use multiple RAID volumes
export NXF_WORK="/raid1/work"
export NXF_TEMP="/raid2/temp"
```

## Advanced Configuration

### Custom Resource Allocation
Edit `conf/profiles/dgx_a100.config`:
```groovy
withName: 'ASSEMBLY_SNPS:CORE_GENOME_ALIGNMENT_PARSNP' {
    cpus   = 64    // Use more CPUs
    memory = 512.GB // Use more memory
    time   = 8.h   // Allow more time
}
```

### GPU Acceleration (Future)
The profile is ready for GPU-accelerated tools:
```groovy
withLabel: process_gpu {
    clusterOptions = '--gres=gpu:a100:1'
}
```

## Monitoring and Profiling

### Resource Usage Reports
```bash
nextflow run main.nf -profile dgx_a100 \
  -with-report execution_report.html \
  -with-timeline execution_timeline.html \
  -with-trace execution_trace.txt
```

### SLURM Monitoring
```bash
# Job efficiency
seff $SLURM_JOB_ID

# Real-time monitoring
watch -n 5 'squeue -u $USER'
```