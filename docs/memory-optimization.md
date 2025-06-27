# Memory Optimization Guide

## Overview

This guide helps you choose the right profile and configuration for your system's memory constraints, particularly for large datasets that can cause out-of-memory (OOM) errors or bus errors.

## System Requirements by Dataset Size

| Dataset Size | Recommended Memory | Recommended Profile | Notes |
|-------------|-------------------|-------------------|-------|
| < 50 genomes | 32GB+ | `docker` or `singularity` | Standard processing |
| 50-200 genomes | 128GB+ | `large_dataset` | Extended memory allocation |
| 200-500 genomes | 512GB+ | `dgx_a100` or `google_vm_large` | High-memory systems |
| 500+ genomes | 1TB+ | `google_vm_large` | Ultra-large datasets |

## Available Profiles

### DGX Station A100 Profile (`dgx_a100`)
- **Target Hardware**: NVIDIA DGX Station A100 (64 CPUs, 512GB RAM)
- **Optimizations**: 
  - Conservative memory allocation (350GB max for Gubbins)
  - Extended processing time for memory-constrained environments
  - Automatic retry on memory-related failures

```bash
nextflow run main.nf -profile dgx_a100 --input data/ --outdir results/
```

### Google Cloud VM Large Profile (`google_vm_large`)
- **Target Hardware**: Google Cloud ultra-high-memory instances (192 vCPUs, 1,536GB RAM)
- **Optimizations**:
  - Maximum memory utilization (1200GB for Gubbins)
  - High CPU parallelization
  - Optimized for very large datasets (500+ genomes)

```bash
nextflow run main.nf -profile google_vm_large --input data/ --outdir results/
```

### Large Dataset Profile (`large_dataset`)
- **Target Hardware**: High-memory workstations (128GB+ RAM)
- **Optimizations**:
  - Balanced resource allocation
  - Good for medium to large datasets (200-500 genomes)

```bash
nextflow run main.nf -profile large_dataset --input data/ --outdir results/
```

## Common Memory Issues and Solutions

### Bus Error (Exit Code 135)
**Cause**: Memory access violation, typically from insufficient memory allocation.

**Solutions**:
1. Use a higher-memory profile:
   ```bash
   # For DGX Station A100
   nextflow run main.nf -profile dgx_a100
   
   # For Google Cloud large instances
   nextflow run main.nf -profile google_vm_large
   ```

2. Increase memory limits manually:
   ```bash
   nextflow run main.nf -profile dgx_a100 --max_memory 480.GB
   ```

### Out of Memory (Exit Code 137)
**Cause**: Process exceeded allocated memory.

**Solutions**:
1. Check system available memory:
   ```bash
   free -h
   ```

2. Use conservative memory allocation:
   ```bash
   nextflow run main.nf -profile dgx_a100 --max_memory 400.GB
   ```

3. For very large datasets, consider splitting the analysis or using cloud instances with more memory.

### Process Timeout
**Cause**: Insufficient time allocation for large datasets.

**Solutions**:
1. Increase time limits:
   ```bash
   nextflow run main.nf -profile dgx_a100 --max_time 240.h
   ```

2. Use profiles with extended time limits (DGX A100 and Google VM profiles have longer default times).

## Memory Allocation by Process

### Gubbins (Recombination Detection)
- **DGX A100**: 350GB (conservative for 512GB system)
- **Google VM Large**: 1200GB (utilizes large memory capacity)
- **Large Dataset**: 600GB (balanced allocation)

### ParSNP (Core Genome Alignment)
- **DGX A100**: 150GB
- **Google VM Large**: 400GB
- **Large Dataset**: 300GB

### Phylogenetic Tree Building
- **DGX A100**: 100GB
- **Google VM Large**: 300GB
- **Large Dataset**: 200GB

## Monitoring and Troubleshooting

### Check System Resources
```bash
# Check available memory
free -h

# Check CPU count
nproc

# Monitor memory usage during run
htop
```

### Nextflow Resource Monitoring
```bash
# Check execution report after run
ls results/pipeline_info/execution_report_*.html

# Check trace file for resource usage
ls results/pipeline_info/execution_trace_*.txt
```

### Common Error Patterns
- **Exit code 135**: Bus error (memory access violation)
- **Exit code 137**: Killed by OOM killer
- **Exit code 143**: Terminated (often timeout)
- **Exit code 130**: Interrupted by user

## Best Practices

1. **Start Conservative**: Begin with a profile that matches your hardware, then adjust if needed.

2. **Monitor Resources**: Use `htop` or similar tools to monitor memory usage during execution.

3. **Leave Memory Buffer**: Don't allocate 100% of available memory; leave 10-20% for the system.

4. **Use Appropriate Profiles**: 
   - DGX Station A100: Use `dgx_a100` profile
   - Google Cloud large instances: Use `google_vm_large` profile
   - Other high-memory systems: Use `large_dataset` profile

5. **Resume Capability**: Use `-resume` flag to restart failed runs without losing progress.

## Profile Comparison

| Feature | dgx_a100 | google_vm_large | large_dataset |
|---------|----------|-----------------|---------------|
| Max Memory | 480GB | 1400GB | 1000GB |
| Max CPUs | 64 | 192 | 64 |
| Gubbins Memory | 350GB | 1200GB | 600GB |
| Target Use Case | DGX Station | Cloud ultra-large | High-memory workstation |
| Dataset Size | 200-500 genomes | 500+ genomes | 200-400 genomes |

## Getting Help

If you continue to experience memory issues:

1. Check the execution report in `results/pipeline_info/`
2. Review the trace file for resource usage patterns
3. Consider using a cloud instance with more memory
4. Contact support with your system specifications and dataset size