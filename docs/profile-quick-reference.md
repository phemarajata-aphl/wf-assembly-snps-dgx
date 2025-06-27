# Profile Quick Reference Guide

## Available Profiles

### Standard Profiles

#### `docker`
- **Use case**: Small to medium datasets (<200 genomes)
- **Requirements**: Any system with Docker
- **Memory**: Standard allocation (6-400GB depending on process)
- **Command**: `nextflow run main.nf -profile docker`

#### `singularity`
- **Use case**: HPC environments, small to medium datasets
- **Requirements**: Singularity installed
- **Memory**: Standard allocation
- **Command**: `nextflow run main.nf -profile singularity`

### High-Memory Profiles

#### `large_dataset`
- **Use case**: Large datasets (200-400 genomes)
- **Requirements**: High-memory workstation (128GB+ RAM)
- **Memory**: Up to 600GB for Gubbins
- **Command**: `nextflow run main.nf -profile large_dataset`

#### `dgx_a100`
- **Use case**: NVIDIA DGX Station A100 systems
- **Requirements**: 64 CPUs, 512GB RAM
- **Memory**: Conservative allocation (350GB max for Gubbins)
- **Optimizations**: Memory-constrained processing, extended time limits
- **Command**: `nextflow run main.nf -profile dgx_a100`

#### `google_vm_large`
- **Use case**: Google Cloud ultra-high-memory instances
- **Requirements**: 192 vCPUs, 1,536GB RAM
- **Memory**: Maximum utilization (1200GB for Gubbins)
- **Optimizations**: Ultra-large dataset processing (500+ genomes)
- **Command**: `nextflow run main.nf -profile google_vm_large`

### HPC Profiles

#### `slurm`
- **Use case**: SLURM-managed clusters
- **Requirements**: SLURM scheduler
- **Command**: `nextflow run main.nf -profile slurm`

#### `aspen_hpc`
- **Use case**: Aspen HPC environment
- **Requirements**: Univa Grid Engine
- **Command**: `nextflow run main.nf -profile aspen_hpc`

#### `rosalind_hpc`
- **Use case**: Rosalind HPC environment
- **Requirements**: Univa Grid Engine
- **Command**: `nextflow run main.nf -profile rosalind_hpc`

## Profile Selection Guide

### By Dataset Size

| Genome Count | Recommended Profile | Alternative |
|-------------|-------------------|-------------|
| < 50 | `docker` or `singularity` | `large_dataset` |
| 50-200 | `large_dataset` | `dgx_a100` |
| 200-500 | `dgx_a100` or `google_vm_large` | `large_dataset` |
| 500+ | `google_vm_large` | `dgx_a100` with extended time |

### By System Type

| System Type | Profile | Notes |
|------------|---------|-------|
| Desktop/Laptop | `docker` | Limited to small datasets |
| Workstation (32-128GB) | `large_dataset` | Good for medium datasets |
| DGX Station A100 | `dgx_a100` | Optimized for 512GB constraint |
| Google Cloud Large VM | `google_vm_large` | Maximum performance |
| SLURM Cluster | `slurm` | HPC environment |
| UGE Cluster | `aspen_hpc` or `rosalind_hpc` | Specific HPC sites |

### By Memory Available

| Available RAM | Recommended Profile | Max Genome Count |
|--------------|-------------------|------------------|
| 32-64GB | `docker` | ~50 genomes |
| 128-256GB | `large_dataset` | ~200 genomes |
| 512GB | `dgx_a100` | ~500 genomes |
| 1TB+ | `google_vm_large` | 1000+ genomes |

## Common Profile Combinations

### Resume from ParSNP outputs
```bash
# DGX Station A100
nextflow run main.nf -profile dgx_a100 --parsnp_outputs /path/to/outputs

# Google Cloud large instance
nextflow run main.nf -profile google_vm_large --parsnp_outputs /path/to/outputs
```

### With custom memory limits
```bash
# Override memory limits
nextflow run main.nf -profile dgx_a100 --max_memory 400.GB

# Override time limits
nextflow run main.nf -profile google_vm_large --max_time 120.h
```

### Test runs
```bash
# Test with small dataset
nextflow run main.nf -profile docker,test

# Test with large dataset profile
nextflow run main.nf -profile large_dataset,test
```

## Troubleshooting Profile Issues

### Profile not found
```bash
# List available profiles
nextflow run main.nf --help

# Check profile syntax
nextflow run main.nf -profile docker --help
```

### Memory issues
```bash
# Check system memory
free -h

# Use conservative profile
nextflow run main.nf -profile dgx_a100  # For 512GB systems
```

### Performance optimization
```bash
# Monitor resource usage
htop

# Check execution report after run
cat results/pipeline_info/execution_report_*.html
```

## Profile Customization

### Override specific parameters
```bash
# Custom memory allocation
nextflow run main.nf -profile dgx_a100 \
  --max_memory 400.GB \
  --max_cpus 48 \
  --max_time 168.h
```

### Combine profiles
```bash
# Use multiple profiles (comma-separated)
nextflow run main.nf -profile docker,test
```

### Environment-specific settings
```bash
# Set cache directories
nextflow run main.nf -profile google_vm_large \
  -c custom.config
```

For detailed memory optimization and troubleshooting, see [Memory Optimization Guide](memory-optimization.md).