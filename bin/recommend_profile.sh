#!/bin/bash

# Profile recommendation script for wf-assembly-snps
# Analyzes system resources and recommends appropriate profile

echo "=== wf-assembly-snps Profile Recommendation ==="
echo "Date: $(date)"
echo ""

# Get system information
TOTAL_MEM_GB=$(free -g | awk '/^Mem:/{print $2}')
TOTAL_CPUS=$(nproc)
AVAILABLE_MEM_GB=$(free -g | awk '/^Mem:/{print $7}')

echo "=== SYSTEM INFORMATION ==="
echo "Total Memory: ${TOTAL_MEM_GB}GB"
echo "Available Memory: ${AVAILABLE_MEM_GB}GB"
echo "Total CPUs: ${TOTAL_CPUS}"
echo ""

# Check for specific systems
echo "=== SYSTEM DETECTION ==="
if [[ $TOTAL_MEM_GB -ge 1400 && $TOTAL_CPUS -ge 180 ]]; then
    SYSTEM_TYPE="Google Cloud Ultra-Large VM"
    RECOMMENDED_PROFILE="google_vm_large"
elif [[ $TOTAL_MEM_GB -ge 480 && $TOTAL_MEM_GB -le 520 && $TOTAL_CPUS -eq 64 ]]; then
    SYSTEM_TYPE="NVIDIA DGX Station A100"
    RECOMMENDED_PROFILE="dgx_a100"
elif [[ $TOTAL_MEM_GB -ge 128 ]]; then
    SYSTEM_TYPE="High-Memory Workstation"
    RECOMMENDED_PROFILE="large_dataset"
elif [[ $TOTAL_MEM_GB -ge 32 ]]; then
    SYSTEM_TYPE="Standard Workstation"
    RECOMMENDED_PROFILE="docker"
else
    SYSTEM_TYPE="Low-Memory System"
    RECOMMENDED_PROFILE="docker (small datasets only)"
fi

echo "Detected System Type: $SYSTEM_TYPE"
echo "Recommended Profile: $RECOMMENDED_PROFILE"
echo ""

# Dataset size recommendations
echo "=== DATASET SIZE RECOMMENDATIONS ==="
echo "Profile: $RECOMMENDED_PROFILE"

case $RECOMMENDED_PROFILE in
    "google_vm_large")
        echo "Recommended for: 500+ genomes"
        echo "Maximum capacity: 1000+ genomes"
        echo "Command: nextflow run main.nf -profile google_vm_large"
        echo "For ultra-large datasets: nextflow run main.nf -profile google_vm_large --recombination_method lightweight"
        ;;
    "dgx_a100")
        echo "Recommended for: 200-500 genomes"
        echo "Maximum capacity: ~500 genomes"
        echo "Command: nextflow run main.nf -profile dgx_a100"
        echo "For memory issues: nextflow run main.nf -profile dgx_a100 --max_memory 400.GB"
        ;;
    "large_dataset")
        echo "Recommended for: 50-400 genomes"
        echo "Maximum capacity: ~400 genomes"
        echo "Command: nextflow run main.nf -profile large_dataset"
        echo "For large datasets: nextflow run main.nf -profile ultra_large_dataset"
        ;;
    "docker")
        if [[ $TOTAL_MEM_GB -lt 32 ]]; then
            echo "Recommended for: <50 genomes"
            echo "Maximum capacity: ~50 genomes"
            echo "WARNING: Limited memory may cause failures with large datasets"
        else
            echo "Recommended for: <200 genomes"
            echo "Maximum capacity: ~200 genomes"
        fi
        echo "Command: nextflow run main.nf -profile docker"
        ;;
esac

echo ""

# Memory warnings
echo "=== MEMORY WARNINGS ==="
if [[ $AVAILABLE_MEM_GB -lt 16 ]]; then
    echo "⚠️  WARNING: Low available memory (${AVAILABLE_MEM_GB}GB)"
    echo "   Consider closing other applications before running the pipeline"
fi

if [[ $TOTAL_MEM_GB -lt 64 ]]; then
    echo "⚠️  WARNING: Limited total memory (${TOTAL_MEM_GB}GB)"
    echo "   Large datasets (>100 genomes) may fail"
    echo "   Consider using cloud instances with more memory"
fi

# Container recommendations
echo ""
echo "=== CONTAINER RECOMMENDATIONS ==="
if command -v docker &> /dev/null; then
    echo "✅ Docker available - recommended for most use cases"
elif command -v singularity &> /dev/null; then
    echo "✅ Singularity available - good for HPC environments"
    echo "   Use: nextflow run main.nf -profile singularity"
else
    echo "❌ No container runtime detected"
    echo "   Please install Docker or Singularity"
fi

# Final recommendations
echo ""
echo "=== FINAL RECOMMENDATIONS ==="
echo "1. Primary profile: $RECOMMENDED_PROFILE"

if [[ $RECOMMENDED_PROFILE == "dgx_a100" ]]; then
    echo "2. For very large datasets (500+ genomes), consider Google Cloud"
    echo "3. Monitor memory usage with: htop"
    echo "4. If bus errors occur, the system may be at memory limit"
elif [[ $RECOMMENDED_PROFILE == "google_vm_large" ]]; then
    echo "2. Excellent for ultra-large datasets"
    echo "3. Consider cost optimization for smaller datasets"
    echo "4. Use preemptible instances for cost savings"
elif [[ $RECOMMENDED_PROFILE == "large_dataset" ]]; then
    echo "2. For datasets >400 genomes, consider cloud instances"
    echo "3. Monitor memory usage during execution"
elif [[ $RECOMMENDED_PROFILE == "docker" ]]; then
    echo "2. For large datasets, consider upgrading system memory"
    echo "3. Use cloud instances for datasets >200 genomes"
fi

echo ""
echo "=== EXAMPLE COMMANDS ==="
echo "Test run:"
echo "  nextflow run main.nf -profile ${RECOMMENDED_PROFILE},test --outdir test_results"
echo ""
echo "Production run:"
echo "  nextflow run main.nf -profile ${RECOMMENDED_PROFILE} --input data/ --outdir results/"
echo ""
echo "Resume from ParSNP outputs:"
echo "  nextflow run main.nf -profile ${RECOMMENDED_PROFILE} --parsnp_outputs outputs/ --outdir results/"

echo ""
echo "For detailed information, see:"
echo "- docs/memory-optimization.md"
echo "- docs/profile-quick-reference.md"
echo ""