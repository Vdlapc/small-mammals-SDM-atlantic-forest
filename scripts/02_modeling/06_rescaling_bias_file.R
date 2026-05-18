# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      06_rescaling_bias_file.R
# Description: Crop the kernel density bias file (generated in QGIS from rodent GBIF records) to each species calibration area, fill NAs with 0, and rescale values to [1, 100] to weight background sampling.
# Stage:       2 - Modeling | Bias File Preparation
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: terra
# Input:        ./output/bias3.tif (KDE from QGIS), ./output/predNA/{species}_predNA.tif
# Output:       ./output/bias/{species}_bias.tif
# =============================================================================


# Bias file
# Crop bias raster to each species calibration area
# Fill NA cells in bias with 0 within the calibration area
# Rescale bias values to [1, 100]


library(terra)

# load re scale function
rescale <- function(x, x.min = NULL, x.max = NULL, new.min = 0, new.max = 1) {
  if(is.null(x.min)) x.min = min(x)
  if(is.null(x.max)) x.max = max(x)
  new.min + (x - x.min) * ((new.max - new.min) / (x.max - x.min))
}


# Load KDE bias raster generated in QGIS
b <- rast("./output/bias3.tif")
plot(b)

# Path to NA mask files — one per species
na_folder = "./output/predNA/"
na_path <-list.files(path = na_folder, patter='*.tif$')
na_files <- paste(na_folder,na_path, sep="")

names <- gsub("./output/predNA/", "", na_files)
names <- gsub("_predNA.tif", "", names)
names


for (i in 1:length(names)){

  maskNA <- rast(na_files[i])

  # Resample bias raster to match the NA mask resolution
  bNA <- resample(b,maskNA)
  bNA <- bNA*maskNA

  # Create a zero-valued mask (same extent as NA mask)
  mask0 <- maskNA - 1

  # Fill NA cells in bias with 0 using na.rm = TRUE
  bias <- sum(mask0, bNA, na.rm = TRUE)

  # Apply NA mask to restrict bias to the study region
  bias <- bias * maskNA

  b.scale <- rescale(x = bias,
                     x.min = minmax(bias)[1], x.max = minmax(bias)[2],
                     new.min = 1, new.max = 100)

    writeRaster(b.scale, paste0("./output/bias/", names[i],"_bias.tif"))
}

##
#