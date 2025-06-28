# Smart Resume Guide for wf-assembly-snps

This guide explains the new smart resume capabilities that allow you to skip the time-consuming `CONVERT_GINGR_TO_FASTA_HARVESTTOOLS` step when resuming from ParSNP outputs.

## Overview

The pipeline now automatically detects existing alignment files and can skip the GINGR conversion step, saving significant time when running multiple recombination analyses or resuming interrupted runs.

## Key Benefits

- **Save time**: Skip 30+ minute GINGR conversion for large datasets
- **Automatic detection**: Pipeline finds existing alignment files automatically
- **Multiple methods**: Works with both Gubbins and ClonalFrameML
- **Flexible options**: Multiple ways to control resume behavior
- **Safe fallbacks**: Multiple file locations checked automatically

## New Parameters

### `--skip_gingr_conversion`
- **Type**: Boolean (true/false)
- **Default**: false
- **Description**: Force skip GINGR conversion if alignment already exists
- **Usage**: `--skip_gingr_conversion`

### `--alignment_file`
- **Type**: String (file path)
- **Default**: null
- **Description**: Specify exact path to existing alignment file
- **Usage**: `--alignment_file /path/to/Parsnp.Core_Alignment.fasta`

### `--resume_from`
- **Type**: String (alignment|recombination|masking|tree)
- **Default**: null
- **Description**: Resume from specific workflow step (future feature)
- **Usage**: `--resume_from alignment`

## How It Works

### Automatic Detection Logic

The pipeline checks for existing alignment files in this order:

1. **User-specified file**: `--alignment_file /path/to/file.fasta`
2. **Previous run output**: `$outdir/Parsnp/Parsnp.Core_Alignment.fasta`
3. **ParSNP outputs**: `$parsnp_outputs/Parsnp.Core_Alignment.fasta`

### Smart Resume Behavior

```bash
# The pipeline automatically:
# 1. Checks for existing alignment files
# 2. Logs what it finds
# 3. Skips GINGR conversion if file exists
# 4. Uses existing file for recombination analysis
```

## Usage Examples

### 1. Automatic Detection (Recommended)

```bash
nextflow run main.nf \
  -profile google_vm_large \
  --parsnp_outputs /path/to/parsnp_outputs \
  --outdir /path/to/results \
  --recombination gubbins \
  --max_memory 1400.GB
```

**What happens:**
- Pipeline automatically detects existing alignment files
- Skips GINGR conversion if alignment found
- Logs: "Auto-detected resume point: alignment file exists"

### 2. Force Skip GINGR Conversion

```bash
nextflow run main.nf \
  -profile google_vm_large \
  --parsnp_outputs /path/to/parsnp_outputs \
  --outdir /path/to/results \
  --recombination gubbins \
  --skip_gingr_conversion \
  --max_memory 1400.GB
```

**What happens:**
- Forces skipping of GINGR conversion
- Fails if no alignment file found
- Useful when you know alignment exists

### 3. Specify Exact Alignment File

```bash
nextflow run main.nf \
  -profile google_vm_large \
  --parsnp_outputs /path/to/parsnp_outputs \
  --outdir /path/to/results \
  --recombination gubbins \
  --alignment_file /path/to/existing/Parsnp.Core_Alignment.fasta \
  --max_memory 1400.GB
```

**What happens:**
- Uses the exact file you specify
- Skips automatic detection
- Useful for custom alignment files

### 4. ClonalFrameML with Resume

```bash
nextflow run main.nf \
  -profile google_vm_large \
  --parsnp_outputs /path/to/parsnp_outputs \
  --outdir /path/to/results \
  --recombination clonalframeml \
  --max_memory 1400.GB
```

**What happens:**
- Same smart resume logic applies
- Works identically for ClonalFrameML
- Saves time for both recombination methods

## Checking Resume Options

Use the provided script to check what resume options are available:

```bash
./bin/check_resume_options.sh /path/to/parsnp_outputs /path/to/results
```

This will show:
- What files are available
- What resume options you can use
- Recommended commands for your situation

## Log Messages to Watch For

### Successful Resume
```
Auto-detected resume point: alignment file exists, skipping GINGR conversion
Skipping CONVERT_GINGR_TO_FASTA_HARVESTTOOLS - using existing alignment file
Found existing alignment file: /path/to/file.fasta
```

### Normal Conversion
```
Running CONVERT_GINGR_TO_FASTA_HARVESTTOOLS to generate alignment file
```

### Errors
```
Cannot skip GINGR conversion - no existing Parsnp.Core_Alignment.fasta file found
Resume from alignment requested but no alignment file found
```

## Troubleshooting

### Problem: "Cannot skip GINGR conversion"
**Solution**: 
- Check if alignment file actually exists
- Use `./bin/check_resume_options.sh` to verify files
- Remove `--skip_gingr_conversion` to allow normal conversion

### Problem: Pipeline still runs GINGR conversion
**Solution**:
- Check log for "Auto-detected" messages
- Verify alignment file exists and is readable
- Use `--skip_gingr_conversion` to force skipping

### Problem: "Alignment file does not exist"
**Solution**:
- Check the exact path in `--alignment_file`
- Ensure file permissions are correct
- Use absolute paths instead of relative paths

## Performance Impact

### Time Savings
- **Small datasets (50-100 genomes)**: 5-15 minutes saved
- **Medium datasets (100-200 genomes)**: 15-30 minutes saved  
- **Large datasets (200+ genomes)**: 30+ minutes saved

### Resource Savings
- **CPU**: No CPU usage during skipped conversion
- **Memory**: No memory allocation for skipped step
- **I/O**: Reduced disk operations

## Best Practices

1. **Always check resume options first**:
   ```bash
   ./bin/check_resume_options.sh /path/to/parsnp_outputs /path/to/results
   ```

2. **Use automatic detection** (recommended approach):
   ```bash
   # Let the pipeline decide automatically
   nextflow run main.nf --parsnp_outputs /path --recombination gubbins
   ```

3. **Keep alignment files** from previous runs:
   - Store in consistent output directory structure
   - Don't delete `Parsnp.Core_Alignment.fasta` files
   - Use descriptive output directory names

4. **Test different recombination methods efficiently**:
   ```bash
   # Run Gubbins first
   nextflow run main.nf --parsnp_outputs /path --recombination gubbins --outdir results_gubbins
   
   # Then ClonalFrameML (will reuse alignment)
   nextflow run main.nf --parsnp_outputs /path --recombination clonalframeml --outdir results_clonal \
     --alignment_file results_gubbins/Parsnp/Parsnp.Core_Alignment.fasta
   ```

## Migration from Previous Versions

### Old Approach
```bash
# Always ran GINGR conversion
nextflow run main.nf --parsnp_outputs /path --recombination gubbins
```

### New Approach
```bash
# Automatically skips GINGR conversion if alignment exists
nextflow run main.nf --parsnp_outputs /path --recombination gubbins
```

**No changes needed** - the new behavior is backward compatible and automatic!

## Future Enhancements

The `--resume_from` parameter is designed for future enhancements that will allow resuming from other workflow steps:

- `--resume_from recombination`: Skip to recombination step
- `--resume_from masking`: Skip to masking step  
- `--resume_from tree`: Skip to tree building step

These features will be implemented in future versions based on user feedback.