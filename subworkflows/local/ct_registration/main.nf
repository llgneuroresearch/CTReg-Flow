
include { REGISTRATION_CT_TO_MNI } from '../../../modules/local/registration/ct_to_mni'

workflow CT_REGISTRATION {

    take:
    ch_ct              // channel: [ val(meta), [ ct ] ]
    ch_mni_template    // channel: [ val(meta), [ mni_template ] ]

    main:

    ch_versions = Channel.empty()

    REGISTRATION_CT_TO_MNI ( ch_ct.combine(ch_mni_template) )
    ch_versions = ch_versions.mix(REGISTRATION_CT_TO_MNI.out.versions.first())

    emit:
    transfo_image = REGISTRATION_CT_TO_MNI.out.transfo_image    // channel: [ val(meta), [ affine ] ]
    ct_warped = REGISTRATION_CT_TO_MNI.out.ct_warped            // channel: [ val(meta), [ image ] ]
    ct_qc = REGISTRATION_CT_TO_MNI.out.ct_qc                    // channel: [ val(meta), [ image ] ]

    versions = ch_versions                                      // channel: [ versions.yml ]
}

