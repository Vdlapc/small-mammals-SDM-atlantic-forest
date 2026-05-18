# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      13_area_calculation.R
# Description: Calculate species distribution area (km²) from binary maps for each scenario. Computes area change (%) and area ratio relative to current scenario. Also calculates log-transformed values.
# Stage:       3 - Analysis | Distribution Area Calculation
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
# Input:        ./output/binary_maps/{scenario}/{species}_dist_1NA.tif
# Output:       ./output/area/area_comparison.csv
# =============================================================================


### Area calculation and summary


library(terra)

# Get scenario names from output directory
sc <- list.files("./output/binary_maps/", full.names = FALSE)


# Empty data frame for TSS and AUC results across all runs
area_df <- as.data.frame(matrix(ncol = 8, nrow = 0))
colnames(area_df)<-c("Scenario","Species","Sqkm", "%Change", "Area ratio", "Sqkm_log", "%Change_log", "Area ratio_log")


for (k in 1) { # current scenario

  # List binary distribution maps for this scenario
  spp.name <- list.files(paste0("./output/binary_maps/", sc[k], "/"), patter = '*_dist_1NA.tif$', full.names = FALSE)


  for (i in 1:length(spp.name)){
    dist.path <- paste0("./output/binary_maps/", sc[k],"/", spp.name[i])
    bin <- rast(dist.path)
    area <- expanse(bin, unit="km")

    area <- area[,2]
    area.c <- area
    change <- 100*((area/area.c)-1)
    ratio <- area/area.c
    sp <- gsub("_dist_1NA.tif", "", spp.name[i])

    area.l <- log(area)
    area.cl <- area.l
    change.l <- 100*((area.l/area.cl)-1)
    ratio.l <- area.l/area.cl

    df <- cbind(sc[k], sp, area, change, ratio, area.l, change.l, ratio.l)
    colnames(df) <- c("Scenario","Species","Sqkm", "%Change", "Area ratio", "Sqkm_log", "%Change_log", "Area ratio_log")


    area_df <- rbind(area_df, df)

  }

} # end of loop


for (k in 2:length(sc)) {

  # List binary distribution maps for this scenario
  spp.name <- list.files(paste0("./output/binary_maps/", sc[k], "/"), patter = '*_dist_1NA.tif$', full.names = FALSE)

  for (i in 1:length(spp.name)){
    dist.path <- paste0("./output/binary_maps/", sc[k],"/", spp.name[i])
    bin <- rast(dist.path)
    area <- expanse(bin, unit="km")
    area <- area[,2]
    area.c <- as.numeric(area_df[i,3])
    change <- 100*((area/area.c)-1)
    ratio <- area/area.c
    sp <- gsub("_dist_1NA.tif", "", spp.name[i])

    area.l <- log(area)
    area.cl <- as.numeric(area_df[i,6])
    change.l <- 100*((area.l/area.cl)-1)
    ratio.l <- area.l/area.cl

    df <- cbind(sc[k], sp, area, change, ratio, area.l, change.l, ratio.l)
    colnames(df) <- c("Scenario","Species","Sqkm", "%Change", "Area ratio", "Sqkm_log", "%Change_log", "Area ratio_log")

    area_df <- rbind(area_df, df)

  }

}


write.csv(area_df, file = "./output/area/area_comparison.csv")