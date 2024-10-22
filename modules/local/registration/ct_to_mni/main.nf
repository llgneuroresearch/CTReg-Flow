

process REGISTRATION_CT_TO_MNI {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_1.6.0.sif':
        'scilus/scilus:1.6.0' }"

    input:
    tuple val(meta), path(ct), path(mni_template)

    output:
    tuple val(meta), path("*0GenericAffine.mat")    , emit: transfo_image
    tuple val(meta), path("*ct_warped.nii.gz")      , emit: ct_warped
    tuple val(meta), path("*ct_qc.nii.gz")          , emit: ct_qc
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cpus = task.ext.cpus ? "$task.ext.cpus" : "1"

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.ext.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=1234

    mrconvert $ct $ct -force -stride 1,2,3
    antsRegistration --dimensionality 3 --float 0\
        --output [output,outputWarped.nii.gz,outputInverseWarped.nii.gz]\
        --interpolation Linear --use-histogram-matching 0\
        --winsorize-image-intensities [0.005,0.995]\
        --initial-moving-transform [$mni_template,$ct,1]\
        --transform Rigid['0.2']\
        --metric MI[$mni_template,$ct,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0\
        --transform Affine['0.2']\
        --metric MI[$mni_template,$ct,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0

    mv outputWarped.nii.gz ${prefix}__ct_warped.nii.gz
    mv output0GenericAffine.mat ${prefix}__output0GenericAffine.mat

    mrcat ${prefix}__ct_warped.nii.gz ${mni_template} ${prefix}__ct_qc.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: 2.4.3
        mrtrix: 3.0.4
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    antsRegistration -h

    touch ${prefix}__ct_warped.nii.gz
    touch ${prefix}__output0GenericAffine.mat
    touch ${prefix}__ct_qc.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: 2.4.3
        mrtrix: 3.0.4
    END_VERSIONS
    """
}