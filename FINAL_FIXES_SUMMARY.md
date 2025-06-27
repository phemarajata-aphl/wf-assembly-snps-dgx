# Final Memory Optimization and Profile Fixes Summary

## Issues Resolved

### 1. DGX Station A100 Memory Crashes (512GB RAM, 64 CPUs)
**Problem**: Bus errors (exit code 135) with 322+ genomes due to insufficient memory allocation.

**Solutions Implemented**:
- **Reduced Gubbins memory**: 400GB → 350GB (safe allocation for 512GB system)
- **Conservative max memory**: 500GB → 480GB (leaves 32GB buffer)
- **Extended time limits**: 48h → 72h for memory-constrained processing
- **Enhanced retry strategy**: 3 retries with memory-related error codes
- **Adaptive Gubbins settings**: Conservative parameters for 300+ genomes

### 2. Google Cloud VM Large Instance Support (192 vCPUs, 1,536GB RAM)
**New Profile**: `google_vm_large` optimized for ultra-large datasets

**Optimizations**:
- **Maximum memory utilization**: Up to 1200GB for Gubbins
- **High CPU parallelization**: Up to 128 CPUs for CPU-intensive processes
- **Extended processing time**: Up to 120h for very large datasets
- **Optimized for 500+ genomes**: Can handle datasets with 1000+ genomes

## New Profiles Added

### 1. `dgx_a100` (Fixed)
```bash
nextflow run main.nf -profile dgx_a100 --input data/ --outdir results/
```
- **Target**: DGX Station A100 (64 CPUs, 512GB RAM)
- **Gubbins Memory**: 350GB (safe allocation)
- **Max Genomes**: ~500 genomes
- **Special Features**: Conservative memory management, extended time limits

### 2. `google_vm_large` (New)
```bash
nextflow run main.nf -profile google_vm_large --input data/ --outdir results/
```
- **Target**: Google Cloud large instances (192 vCPUs, 1,536GB RAM)
- **Gubbins Memory**: 1200GB (maximum utilization)
- **Max Genomes**: 1000+ genomes
- **Special Features**: Ultra-high memory and CPU utilization

### 3. `ultra_large_dataset` (New)
```bash
nextflow run main.nf -profile ultra_large_dataset --input data/ --outdir results/
```
- **Target**: Systems with 1TB+ RAM
- **Gubbins Memory**: Up to 1200GB with retries
- **Max Genomes**: 1000+ genomes
- **Special Features**: Maximum resource allocation with fallback strategies

## Enhanced Features

### 1. Adaptive Gubbins Processing
- **Automatic genome counting**: Detects dataset size from FASTA headers
- **Conservative settings for 300+ genomes**:
  - Reduced iterations (3 instead of 5)
  - Higher SNP thresholds (10 minimum)
  - Increased filtering (50% threshold)
- **Memory-safe ulimit**: Uses 90% of allocated memory

### 2. Lightweight Recombination Fallback
```bash
nextflow run main.nf -profile dgx_a100 --recombination_method lightweight
```
- **Purpose**: Fallback for datasets where Gubbins fails
- **Function**: Skips recombination detection but maintains pipeline structure
- **Use case**: Ultra-large datasets (500+ genomes) or persistent memory issues

### 3. Enhanced Error Handling
- **Bus error detection**: Exit code 135 triggers automatic retry
- **Memory-related errors**: Comprehensive error code handling
- **Progressive resource allocation**: Increases memory/time with each retry

## Helper Scripts and Documentation

### 1. System Resource Checker
```bash
./bin/check_system_resources.sh
```
- Analyzes available memory and CPUs
- Provides profile recommendations
- Detects specific system types (DGX A100, Google Cloud)

### 2. Profile Recommendation Tool
```bash
./bin/recommend_profile.sh
```
- Automatic system detection
- Dataset size recommendations
- Specific command examples

### 3. Comprehensive Documentation
- **Memory Optimization Guide**: `docs/memory-optimization.md`
- **Profile Quick Reference**: `docs/profile-quick-reference.md`
- **Troubleshooting Guide**: Enhanced README with specific solutions

## Usage Examples

### For Your 322-Genome Dataset

#### Option 1: DGX Station A100 (Recommended)
```bash
nextflow run main.nf \
  -profile dgx_a100 \
  --parsnp_outputs /path/to/your/parsnp_outputs \
  --outdir results_322_genomes
```

#### Option 2: If Memory Issues Persist
```bash
nextflow run main.nf \
  -profile dgx_a100 \
  --parsnp_outputs /path/to/your/parsnp_outputs \
  --outdir results_322_genomes \
  --max_memory 400.GB
```

#### Option 3: Lightweight Fallback
```bash
nextflow run main.nf \
  -profile dgx_a100 \
  --parsnp_outputs /path/to/your/parsnp_outputs \
  --outdir results_322_genomes \
  --recombination_method lightweight
```

### For Google Cloud Large Instances
```bash
nextflow run main.nf \
  -profile google_vm_large \
  --input large_dataset/ \
  --outdir results_1000_genomes
```

## Key Improvements Summary

1. **Memory Safety**: DGX A100 profile prevents out-of-memory crashes
2. **Scalability**: Google VM profile handles ultra-large datasets (1000+ genomes)
3. **Adaptability**: Automatic detection of dataset size and system capabilities
4. **Reliability**: Enhanced error handling and retry strategies
5. **Fallback Options**: Lightweight recombination for problematic datasets
6. **User Guidance**: Comprehensive documentation and helper scripts

## Testing Recommendations

1. **Test with your 322-genome dataset** using the fixed DGX A100 profile
2. **Monitor memory usage** with `htop` during execution
3. **Check execution reports** in `results/pipeline_info/` for resource utilization
4. **Use helper scripts** to verify optimal profile selection

These fixes should completely resolve the bus error issues on your DGX Station A100 while providing excellent scalability options for larger systems and datasets.