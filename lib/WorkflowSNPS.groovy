//
// This file holds several functions specific to the workflow/blast.nf in the wf-assembly-snps pipeline
//

import groovy.text.SimpleTemplateEngine

class WorkflowSNPS {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        if (!params.input && !params.parsnp_outputs) {
            log.error "Either --input directory or --parsnp_outputs directory is required to perform analysis."
            System.exit(1)
        }
        
        // Validate resume parameters
        if (params.skip_gingr_conversion && !params.parsnp_outputs) {
            log.error "--skip_gingr_conversion can only be used with --parsnp_outputs"
            System.exit(1)
        }
        
        if (params.alignment_file && !params.parsnp_outputs) {
            log.error "--alignment_file can only be used with --parsnp_outputs"
            System.exit(1)
        }
        
        if (params.alignment_file) {
            def alignment_file = new File(params.alignment_file)
            if (!alignment_file.exists()) {
                log.error "Specified alignment file does not exist: ${params.alignment_file}"
                System.exit(1)
            }
        }
        
        if (params.resume_from && !params.parsnp_outputs) {
            log.error "--resume_from can only be used with --parsnp_outputs"
            System.exit(1)
        }
        
        if (params.resume_from && !['alignment', 'recombination', 'masking', 'tree'].contains(params.resume_from)) {
            log.error "--resume_from must be one of: alignment, recombination, masking, tree"
            System.exit(1)
        }
    }
}
