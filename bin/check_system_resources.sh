#!/bin/bash

# System Resource Checker for wf-assembly-snps
# This script checks if your system has sufficient resources for large datasets

echo "=== wf-assembly-snps System Resource Checker ==="
echo "Date: $(date)"
echo

# Check available memory
echo "=== Memory Information ==="
total_mem_gb=$(free -g | awk '/^Mem:/{print $2}')
available_mem_gb=$(free -g | awk '/^Mem:/{print $7}')
echo "Total Memory: ${total_mem_gb}GB"
echo "Available Memory: ${available_mem_gb}GB"

if [ "$available_mem_gb" -lt 100 ]; then
    echo "⚠️  WARNING: Less than 100GB available memory"
    echo "   Recommended for large datasets (200+ genomes): 600GB+"
elif [ "$available_mem_gb" -lt 300 ]; then
    echo "⚠️  CAUTION: Memory may be insufficient for very large datasets"
    echo "   Current: ${available_mem_gb}GB, Recommended: 600GB+"
else
    echo "✅ Memory looks sufficient for large datasets"
fi
echo

# Check CPU cores
echo "=== CPU Information ==="
cpu_cores=$(nproc)
echo "CPU Cores: ${cpu_cores}"

if [ "$cpu_cores" -lt 8 ]; then
    echo "⚠️  WARNING: Less than 8 CPU cores available"
    echo "   Recommended for large datasets: 16+ cores"
elif [ "$cpu_cores" -lt 16 ]; then
    echo "⚠️  CAUTION: More CPU cores recommended for large datasets"
    echo "   Current: ${cpu_cores}, Recommended: 16+"
else
    echo "✅ CPU cores look sufficient for large datasets"
fi
echo

# Check disk space
echo "=== Disk Space Information ==="
current_dir_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
echo "Available space in current directory: ${current_dir_space}GB"

if [ "$current_dir_space" -lt 100 ]; then
    echo "⚠️  WARNING: Less than 100GB available disk space"
    echo "   Recommended for large datasets: 500GB+"
elif [ "$current_dir_space" -lt 300 ]; then
    echo "⚠️  CAUTION: More disk space recommended for large datasets"
    echo "   Current: ${current_dir_space}GB, Recommended: 500GB+"
else
    echo "✅ Disk space looks sufficient for large datasets"
fi
echo

# Check if Docker/Singularity is available
echo "=== Container Runtime ==="
if command -v docker &> /dev/null; then
    echo "✅ Docker is available"
    docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "   Version: ${docker_version}"
elif command -v singularity &> /dev/null; then
    echo "✅ Singularity is available"
    singularity_version=$(singularity --version)
    echo "   Version: ${singularity_version}"
else
    echo "⚠️  WARNING: Neither Docker nor Singularity found"
    echo "   Please install Docker or Singularity to run the pipeline"
fi
echo

# Check if Nextflow is available
echo "=== Nextflow ==="
if command -v nextflow &> /dev/null; then
    echo "✅ Nextflow is available"
    nextflow_version=$(nextflow -version | head -n1 | cut -d' ' -f3)
    echo "   Version: ${nextflow_version}"
else
    echo "⚠️  WARNING: Nextflow not found"
    echo "   Please install Nextflow to run the pipeline"
fi
echo

# Provide recommendations based on system
echo "=== Recommendations ==="
if [ "$available_mem_gb" -ge 600 ] && [ "$cpu_cores" -ge 16 ] && [ "$current_dir_space" -ge 500 ]; then
    echo "✅ Your system appears well-suited for large datasets (300+ genomes)"
    echo "   Recommended command:"
    echo "   nextflow run main.nf -profile large_dataset --input data/ --outdir results/"
elif [ "$available_mem_gb" -ge 300 ] && [ "$cpu_cores" -ge 8 ] && [ "$current_dir_space" -ge 200 ]; then
    echo "⚠️  Your system can handle medium datasets (100-200 genomes)"
    echo "   For larger datasets, consider:"
    echo "   - Using a high-memory system"
    echo "   - Reducing dataset size"
    echo "   - Using HPC cluster"
    echo "   Recommended command:"
    echo "   nextflow run main.nf -profile docker --max_memory ${available_mem_gb}.GB --input data/ --outdir results/"
else
    echo "⚠️  Your system may struggle with large datasets"
    echo "   Recommendations:"
    echo "   - Use smaller datasets (<100 genomes)"
    echo "   - Consider cloud computing or HPC"
    echo "   - Increase system resources"
fi
echo

# Check for common issues
echo "=== Common Issue Checks ==="

# Check ulimits
ulimit_v=$(ulimit -v)
if [ "$ulimit_v" != "unlimited" ] && [ "$ulimit_v" -lt 1000000000 ]; then
    echo "⚠️  Virtual memory limit may be too low: $ulimit_v"
    echo "   Consider running: ulimit -v unlimited"
fi

# Check swap space
swap_total=$(free -g | awk '/^Swap:/{print $2}')
if [ "$swap_total" -eq 0 ]; then
    echo "⚠️  No swap space configured"
    echo "   Consider adding swap space for large datasets"
fi

echo "✅ System check complete!"
echo
echo "For more information on handling large datasets, see:"
echo "docs/large-datasets.md"