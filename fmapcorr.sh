#!/bin/bash
# ================================================================
# Fieldmap Correction for sub-ds02 BOLD using FSL
# Based on Diedrichsen Lab & BMI Guidelines
# ================================================================

set -euo pipefail

IFS=$'\n\t'

# ----------------------
# Configuration
# ----------------------
SUBJECT="sub-ds02"
DERIV_DIR="derivatives/fmap/${SUBJECT}"
FUNC_DIR="${SUBJECT}/func"
FMAP_DIR="${SUBJECT}/fmap"

# ----------------------
# Input Files
# ----------------------
BOLD="${FUNC_DIR}/${SUBJECT}_task-rest_bold.nii.gz"
PHASEDIFF="${FMAP_DIR}/${SUBJECT}_run-01_phasediff.nii.gz"
MAG1="${FMAP_DIR}/${SUBJECT}_run-01_magnitude1.nii.gz"
MAG2="${FMAP_DIR}/${SUBJECT}_run-01_magnitude2.nii.gz"

# ----------------------
# Output Files
# ----------------------
FIELDMAP="${DERIV_DIR}/${SUBJECT}_run-01_fmap_rads.nii.gz"
BOLD_CORR="${DERIV_DIR}/${SUBJECT}_task-rest_bold_corrected.nii.gz"

# ----------------------
# Acquisition Parameters
# ----------------------
TE1=0.004           # Echo time 1 (s)
TE2=0.00646         # Echo time 2 (s)
DWELL=0.00055       # Effective echo spacing (s)
DELTA_TE=$(bc -l <<< "$TE2 - $TE1")  # Echo time difference

# ----------------------
# Create output directories
# ----------------------
mkdir -p "${DERIV_DIR}"

echo "=== Starting fieldmap correction for ${SUBJECT} ==="
echo "TE1=${TE1}, TE2=${TE2}, ΔTE=${DELTA_TE}s, DWELL=${DWELL}s"

# ----------------------
# Step 1: Reorient images
# ----------------------
echo "[1/5] Reorienting images to FSL standard..."
fslreorient2std "$MAG2" "${DERIV_DIR}/mag2_std"
fslreorient2std "$PHASEDIFF" "${DERIV_DIR}/phasediff_std"

# ----------------------
# Step 2: Bias correction
# ----------------------
echo "[2/5] Running bias correction (fsl_anat)..."
fsl_anat --strongbias --nocrop --noreg --nosubcortseg --noseg \
  -i "${DERIV_DIR}/mag2_std" -o "${DERIV_DIR}/mag2_anat"

# ----------------------
# Step 3: Skull stripping
# ----------------------
echo "[3/5] Performing skull stripping..."
BET_INPUT="${DERIV_DIR}/mag2_anat.anat/T1_biascorr.nii.gz"
BET_OUTPUT="${DERIV_DIR}/mag2_brain"
bet "$BET_INPUT" "$BET_OUTPUT" -R

# Erode for conservative mask
fslmaths "$BET_OUTPUT" -ero "${DERIV_DIR}/mag2_brain_ero1"
fslmaths "${DERIV_DIR}/mag2_brain_ero1" -ero "${DERIV_DIR}/mag2_brain_ero2"

# Choose best skull-stripped version
CHOSEN_BRAIN="${DERIV_DIR}/mag2_brain_ero1"

# ----------------------
# Step 4: Prepare fieldmap
# ----------------------
echo "[4/5] Preparing fieldmap..."
fsl_prepare_fieldmap SIEMENS \
  "${DERIV_DIR}/phasediff_std" \
  "$CHOSEN_BRAIN" \
  "$FIELDMAP" \
  "$(awk "BEGIN {print ($DELTA_TE * 1000)}")"  # convert to ms if needed

# ----------------------
# Step 5: Apply correction to BOLD
# ----------------------
echo "[5/5] Applying fieldmap correction to BOLD..."
fugue -i "$BOLD" \
  --dwell="$DWELL" \
  --loadfmap="$FIELDMAP" \
  -u "$BOLD_CORR" \
  --unwarpdir=y-

echo "=== Fieldmap correction completed successfully! ==="
echo "Corrected BOLD saved at: $BOLD_CORR"
