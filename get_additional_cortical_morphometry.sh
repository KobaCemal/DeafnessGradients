#!/bin/bash

# Set FreeSurfer SUBJECTS_DIR to your dataset derivatives folder
target_folder=/mnt/compneuro/deafness_datasets/Krakow/derivatives/fastsurfer
export SUBJECTS_DIR=$target_folder

cd $target_folder

# =========================
# 1. Glasser 360 Statistics
# =========================
sub_list=$(ls | grep -v fs)
for sub in $sub_list; do
    for hemi in lh rh; do
        echo " "
        echo "=========================== Processing $sub $hemi ==========================="

        # Cortical thickness
        mris_anatomical_stats \
            -a "$target_folder/$sub/label/${hemi}.glasser-360_mics.annot" \
            -b "$sub" "$hemi" \
            > "$target_folder/$sub/stats/${hemi}.glasser.stats"

        # Sulcal depth
        mris_anatomical_stats \
            -a "$target_folder/$sub/label/${hemi}.glasser-360_mics.annot" \
            -t "$target_folder/$sub/surf/${hemi}.sulc" \
            -b "$sub" "$hemi" \
            > "$target_folder/$sub/stats/${hemi}.glasser_sulc.stats"
    done
done


# ==========================================
# 2. Convert data from subject → fsaverage5
# ==========================================
cd $target_folder

for sub in $sub_list; do
    for morph in sulc area volume; do
        for hemi in lh rh; do
            echo "=========================================== Processing sub $sub $hemi $morph"

            # Convert surface morphometry files to .mgh format
            mri_convert \
                "$target_folder/$sub/surf/${hemi}.${morph}" \
                "$target_folder/$sub/surf/${hemi}.${morph}_fsnative.mgh"

            # Project to fsaverage5 space
            mri_surf2surf \
                --s "$sub" \
                --sval "$target_folder/$sub/surf/${hemi}.${morph}_fsnative.mgh" \
                --trgsubject fsaverage5 \
                --tval "$target_folder/$sub/surf/${hemi}.${morph}_fsaverage5.mgh" \
                --hemi "$hemi"
        done
    done
done
