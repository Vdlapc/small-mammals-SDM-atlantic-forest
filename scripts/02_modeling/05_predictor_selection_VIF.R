# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      05_predictor_selection_VIF.R
# Description: Select final predictor variables per species using Variance Inflation Factor (VIF < 10) to remove multicollinearity. 
# Saves selected rasters for each species.
# Stage:       2 - Modeling | Predictor Selection (VIF)
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: terra, usdm, dismo
# Input:        ./output/predictors/sps/{species}/*.tif, ./data/pts/SpeciesRecords_modelo.csv
# Output:       ./output/vif/pred_vif/{species}/*.tif, ./output/vif/vif_results_{species}.csv
# =============================================================================


### select predictors to remove highly correlated variables

library(usdm)
library(dismo)
library(terra)


# Load species occurrence data
pts<- read.csv("./data/pts/SpeciesRecords_modelo.csv")
pts$scientificName <- gsub(" ", "_", pts$scientificName)
names <- unique(pts$scientificName)
names

# Load calibration predictor layers
### loop for NA mask for each species

for (i in 1:length(names)){

  pred_folder = paste0("./output/predictors/sps/",names[i], "/")
  pred_path <-list.files(path = pred_folder, patter='*.tif$')
  pred_files <- paste(pred_folder,pred_path, sep="")

  r <- rast(pred_files) # load all predictor rasters
  names(r)
  r <- c(r[[5:7]],r[[10:16]]) # keep only biologically meaningful variables
                              # NOTE: indices here refer to layer positions, not bioclimatic variable numbers


  set.seed(2023) # fixed seed for reproducibility across model comparisons

  bg <- spatSample(r, 1000, "random", na.rm=TRUE, as.df=TRUE, exp = 1)

  # Select a variables subset with VIF < 10
  # and select the subset of variables
  v <- vifstep(bg, th = 10)

  c.file <- paste0("./output/vif/vif_cormatrix_", names[i], ".csv")
  write.csv(v@corMatrix, c.file, fileEncoding = "UTF-8")

  v.file <- paste0("./output/vif/vif_results_", names[i], ".csv")
  write.csv(v@corMatrix, v.file, fileEncoding = "UTF-8")

  # Save VIF-selected predictor rasters
  n <- v@results[,1]
  p <- subset(r, n)

  out.dir <- paste0("./output/vif/pred_vif/", names[i], "/")
  dir.create(out.dir)
  writeRaster(p, paste0(out.dir,names(p),".tif"))

}

#