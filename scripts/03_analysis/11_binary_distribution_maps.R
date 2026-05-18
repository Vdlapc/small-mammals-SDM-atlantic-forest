# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      11_binary_distribution_maps.R
# Description: Convert continuous suitability maps to binary presence/absence using the Maximum TSS threshold. Clips output to 200 km MCP buffer around occurrence records to avoid overprediction.
# Stage:       3 - Analysis | Binary Distribution Maps
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: terra, dplyr
# Input:        ./output/models/{scenario}/{species}/{species}_cbi.tif, ./output/evaluation/01_validation_average.csv, ./data/pts/SpeciesRecords_modelo.csv
# Output:       ./output/binary_maps/{scenario}/{species}_dist_bin.tif, {species}_dist_1NA.tif
# =============================================================================


###### Distribution range maps
## binary maps from models
## buffer


library(terra)
library(dplyr)


# Load occurrence data
xy_all<- read.csv("./data/pts/SpeciesRecords_modelo.csv")
#xy_all$sp <- gsub(" ", "_", xy_all$scientificName)

# Load species names and evaluation metrics for thresholding
metric_average <- read.csv("./output/evaluation/01_validation_average.csv", row.names = 1)
spp.name <- unique(metric_average$species)
sc <- as.vector(unique(metric_average$scenario))

sc <- c("current","ssp126","ssp245","ssp585")

for (k in 1:length(sc)){

  for (i in 1:length(spp.name)){
    # Simple mean of valid replicates
    sdm_avg <- rast(paste0("./output/models/",sc[k], "/", spp.name[i], "/", spp.name[i],"_cbi.tif"))

    # Retrieve averaged threshold for binarisation
    threshold10 <- as.numeric(subset(metric_average,
                                     grepl(spp.name[i],metric_average$species) & grepl(sc[k],metric_average$scenario),
                                     select = Bin.Prob))

    # Apply threshold to generate binary presence/absence map
    sdm_bin <- sdm_avg >= threshold10
    #sdm_bin <- project(sdm_bin, "EPSG:4326")

    # Clip binary map to MCP + buffer to avoid overprediction
    # occurrence records
    xy <- xy_all[xy_all$scientificName==spp.name[i],]
    pts <- vect(xy, crs = "epsg:4326", geom = c("x", "y"))

    # Build Minimum Convex Polygon around occurrence records
    mcp <- convHull(pts)
    b <- buffer(mcp, 200000) # 200km buffer
    m <- mask(sdm_bin,b) # clip sdm binary models to buffer extent
    writeRaster(m, filename= paste0("./output/binary_maps/", sc[k], "/", spp.name[i],"_dist_bin.tif"), overwrite=T)

    # Retain only presence pixels (NA elsewhere)
    m1 <- m/m
    writeRaster(m1, filename= paste0("./output/binary_maps/", sc[k], "/", spp.name[i],"_dist_1NA.tif"), overwrite=T)

  }

} # end of loop for scenarios