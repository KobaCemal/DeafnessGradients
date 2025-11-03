#!/bin/bash
set -euo pipefail

bids=/mnt/compneuro/deafness_datasets/Krakow/
out=/mnt/compneuro/deafness_datasets/Krakow/derivatives/
fs_lic=/mnt/compneuro/license.txt
sublist=$(cat /mnt/compneuro/deafness_datasets/source/krakow_subjects.txt | cut -d '-' -f2)

for sub in $sublist; do
  docker run -ti --rm \
    -v ${bids}:/bids \
    -v ${out}:/out \
    -v ${fs_lic}:/opt/licence.txt \
    micalab/micapipe:v0.2.3 \
      -bids /bids -out /out -fs_licence /opt/licence.txt \
      -proc_structural -proc_surf -post_structural -GD \
      -proc_func -mainScanStr task-rest_bold -noFIX -NSR -threads 26 -QC_subj \
      -sub sub-${sub}
done
#      -proc_dwi -dwi_main /mnt/compneuro/deafness_datasets/Krakow/sub-"$sub"/dwi/sub-"$sub"_dir-LR_run-01_dwi.nii.gz \
#      -SC -tracts 25M
