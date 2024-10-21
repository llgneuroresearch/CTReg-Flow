#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_pipeline/pipeline_initialisation'
include { CT_REGISTRATION } from './subworkflows/local/ct_registration'

//
// WORKFLOW: Run main pipeline
//
workflow CT_REGISTRATION_TO_MNI {

    take:
    ct              // channel: [ val(meta), [ ct ] ]
    mni_template    // channel: [ val(meta), [ mni_template ] ]

    main:

    //
    // WORKFLOW: Run registration
    //
    CT_REGISTRATION (
        ct,
        Channel.from(file(params.mni_template))
    )

    emit:
    ct_warped = CT_REGISTRATION.out.ct_warped // channel: [ val(meta), [ image ] ]
    transfo_image = CT_REGISTRATION.out.transfo_image // channel: [ val(meta), [ affine ] ]

}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.input,
        params.mni_template,
        params.output_dir,
    )

    //
    // WORKFLOW: Run main workflow
    //
    CT_REGISTRATION_TO_MNI (
        PIPELINE_INITIALISATION.out.input,
        PIPELINE_INITIALISATION.out.mni_template.first()
    )
}
