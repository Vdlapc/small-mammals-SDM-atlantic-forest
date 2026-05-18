# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      02b_calibration_area_predictor.R
# Description: Crop and mask bioclimatic predictors to the calibration area (MCP + 200km buffer) for each species individually.
# Stage:       1 - Preprocessing | Species-level Predictor Masking
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: terra, sf
# Input:        ./output/predictors/current/cropped/*.tif, ./data/pts/SpeciesRecords_semoutlier.csv
# Output:       ./output/predictors/sps/{species}/*.tif, ./output/mcp_shp_buffer_AMS/{species}.shp
# =============================================================================

library(terra)


# Load predictor layers

# Load WorldClim layers cropped in script 01
bio_folder = "./output/predictors/current/cropped/"
bio_path <-list.files(path = bio_folder, patter='*.tif$')
bio_files <- paste(bio_folder,bio_path, sep="")
bio <- rast(bio_files)
plot(bio[[1]])

pts <- spatSample(bio, size = 1000, method = "random", na.rm = TRUE)
c <-pairs(pts, pch = 20, cex = 0.5)

correl <- cor(pts, method='pearson')
correl[1,]


write.table(correl, "./output/correlacao_area_estudo/correl_area_estudo.csv")
write.xlsx(correl, file = "./output/correlacao_area_estudo/correl_area_estudo.xlsx", rowNames = T)
