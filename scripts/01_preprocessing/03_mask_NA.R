# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      03_mask_NA.R
# Description: Generate a single NA mask raster per species by combining all predictor layers. Cells are NA where any predictor has no data, ensuring spatial consistency across variables.
# Stage:       1 - Preprocessing | NA Mask Generation
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
# Input:        ./output/predictors/sps/{species}/*.tif
# Output:       ./output/predNA/{species}_predNA.tif
# =============================================================================


## Making Raster with all NA values from all predictors raster files
# Load species occurrence data
# Load calibration predictor layers
### loop for NA mask for each species

library(terra)

# Load species occurrence data
names <- list.dirs("./output/predictors/sps/", full.names = F)
names <- basename(names)

# Remove empty entry corresponding to the root directory
names<- names[names != ""]
names

pts_filtrado <- pts[pts$scientificName %in% names, ]
pts_filtrado$scientificName
unique(pts_filtrado$scientificName)

write.csv(pts_filtrado, "./data/pts/speciesRecords_model.csv", row.names = FALSE,  quote = FALSE)


#### OPTION 1 ####
# Load calibration predictor layers
### loop for NA mask for each species

for (i in 1:length(names)){

  pred_folder = paste0("./output/predictors/sps/",names[i], "/")
  pred_path <-list.files(path = pred_folder, patter='*.tif$')
  pred_files <- paste(pred_folder,pred_path, sep="")

  pred0 <- rast(pred_files)
  plot(pred0)
  # Replace zeros before dividing to avoid zero-division artefacts
  # Substitute zeros with 100 to avoid division issues

  pred <- subst(pred0, 0,100)
  pred <- pred/pred
  # Multiply all layers: result is NA wherever any layer has NA
  predNA <- prod(pred,  na.rm = FALSE)

  writeRaster(predNA, paste0("./output/predNA/", names[i],"_predNA.tif"))

}

#### OPTION 2 ####
## Making Raster with all NA values from all predictors raster files

library(terra)

# Load species occurrence data
pts<- read.csv("./data/TableS1_SpeciesRecords.csv")
pts$sp <- gsub(" ", "_", pts$sp)
#names <- unique(pts$sp)
names <- unique(pts$sp)[1:3]


# Load calibration predictor layers
### loop for NA mask for each species

for (i in 1:length(names)){

  pred_folder = paste0("./output/predictors/",names[i], "/")
  pred_path <-list.files(path = pred_folder, patter='*.tif$')
  pred_files <- paste(pred_folder,pred_path, sep="")

  pred <- rast(pred_files)

  # replace cell values 0 for 1
  pred_m2 <- subst(pred, 0, 1)

  #divide all layers by itself to get layers with value 1 for all cells with value
  pred_01 <- pred_m2/pred_m2

  #multiply all layers to have a single layer with NA in all layers
  predNA <- prod(pred_01,  na.rm = FALSE)

  plot(predNA, main = paste0("NA mask ", names[i]))
  writeRaster(predNA, paste0("./output/predNA2/", names[i],"_predNA.tif"))
}