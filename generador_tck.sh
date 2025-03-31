
FA_thr=0.10
minlen_thr=30
maxlen_thr=1000


outputPath="/Users/ramoncito/CIMAT Drive/Investigacion/Tractography Judith/dataset/Tractos/datos"
path2DWIs="/Users/ramoncito/CIMAT Drive/Investigacion/Tractography Judith/dataset/DWIs"

path2Data="${path2DWIs}"

mkdir -p "${outputPath}/DT"
mkdir -p "${outputPath}/temp"
mkdir -p "${outputPath}/CSD"

path2DT="${outputPath}/DT"
path2Temp="${outputPath}/temp"
path2CSD="${outputPath}/CSD"
path2CSD="${outputPath}/Tracto"

DWIs="ISMRM_2023_b3000.nii.gz"
bval="ISMRM_2023_b3000.bval"
bvecs="ISMRM_2023_b3000.bvec"

path2bvecs="${path2Data}/${bvecs}"
path2bvals="${path2Data}/${bval}"

base_name="ISMRM_2023_b3000"

Mask="${outputPath}/${base_name}_mask.nii"

###################
### Mascaras y b0
#
dwi2mask "${path2Data}/${DWIs}" -fslgrad "${path2bvecs}" "${path2bvals}" "${outputPath}/${base_name}_mask.nii" -force


dwiextract "${path2Data}/${DWIs}" -fslgrad "${path2bvecs}" "${path2bvals}" "${outputPath}/${base_name}_b0s.nii" -shells 0 -force

mrmath "${outputPath}/${base_name}_b0s.nii" mean "${outputPath}/${base_name}_b0_mean.nii" -axis 3 -force

##################
## Tensor y FA
dwi2tensor "${path2Data}/${DWIs}" -fslgrad "${path2bvecs}" "${path2bvals}" "${path2DT}/${base_name}_DT.nii" -force -mask "${Mask}"
        
tensor2metric "${path2DT}/${base_name}_DT.nii" -fa "${path2DT}/${base_name}_FA.nii" -mask "${Mask}" -force

# mask from FA_thr
mrthreshold "${path2DT}/${base_name}_FA.nii" "${path2Temp}/${base_name}_MASK_FA_temp.nii" -comparison ge -abs ${FA_thr} -force

maskfilter "${path2Temp}/${base_name}_MASK_FA_temp.nii" dilate "${path2Temp}/${base_name}_MASK_FA_Dilate_temp.nii" -force
maskfilter "${path2Temp}/${base_name}_MASK_FA_Dilate_temp.nii" erode "${path2DT}/${base_name}_Mask_FA_${FA_thr}.nii" -force



##################
# Reconstrucción intravoxel CSD

dwi2response fa "${path2Data}/${DWIs}" -fslgrad "${path2bvecs}" "${path2bvals}" "${path2CSD}/out_sfwm_fa.txt" -mask "${Mask}" -force

dwi2fod csd "${path2Data}/${DWIs}" -fslgrad "${path2bvecs}" "${path2bvals}" "${path2CSD}/out_sfwm_fa.txt" "${path2CSD}/${base_name}_CSF.nii.gz" -mask "${Mask}" -force

sh2peaks "${path2CSD}/${base_name}_CSF.nii.gz" "${path2CSD}/${base_name}_PEAKS.nii.gz" -num 5 -force



#Tractografia

tckgen -algorithm FACT "${path2CSD}/${base_name}_PEAKS.nii.gz" "${base_name}_FACT.tck" -seed_image "${Mask}" -force

tckgen -algorithm iFOD2 "${path2CSD}/${base_name}_CSF.nii.gz" "${base_name}_iFOD2.tck" -seed_image "${Mask}" -force
