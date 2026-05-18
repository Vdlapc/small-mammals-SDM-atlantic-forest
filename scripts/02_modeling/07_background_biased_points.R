# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      07_background_biased_points.R
# Description: Generate SWD (Sample With Data) tables for occurrences and background points. Background is sampled proportionally to the bias file (10,000 pts or 80% if fewer available), removing occurrence cells.
# Stage:       2 - Modeling | Background & SWD Preparation
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
# Input:        ./output/vif/pred_vif/{species}/*.tif, ./output/bias/{species}_bias.tif, ./output/pts_thin/xy_{species}.csv
# Output:       ./output/xySWD/xySWD_{species}.csv, ./output/biasSWD/biasSWD_{species}.csv, ./output/envSWD/envSWD_{species}.csv
# =============================================================================


# generating background points with bias file


library(terra)

names <- list.files("./output/vif/pred_vif/")
names


for (i in 1:length(names)){

  # predictor files
  pred.folder <- paste0("./output/vif/pred_vif/", names[i])
  pred.files <- list.files(pred.folder, patter='*.tif$')
  pred <- rast(paste0(pred.folder,"/",pred.files))

  # Bias file
  bias <- rast(paste0("./output/bias/",names[i],"_bias.tif"))

  # Extract all cell coordinates and values from the bias raster
  xy <- xyFromCell(bias, cells(bias)) 
  c <- cells(bias)
  v <- values(bias, dataframe = T, na.rm = T)

  KDEpts <- cbind(c,xy,v) # combine all together
  colnames(KDEpts) <- c("cell", "x", "y", "prob")

  ## occurrence records
  occ <- read.csv(paste0("./output/pts_thin/xy_", names[i], ".csv"))

  # Extract raster cell IDs and coordinates for occurrence points
  o <-extract(bias,occ[,5:6], cells = T, xy = TRUE)

  # Extract predictor values for occurrence points
  xySWD <- as.data.frame(extract(pred, o[,3]))
  species <- rep(names[i],nrow(o))
  xySWD <- cbind(species, o[,3:5], xySWD)
  write.csv(xySWD, paste0("./output/xySWD/xySWD_",names[i],".csv"))

  # Remove occurrence cells from background pool
  KDEpts <- subset(KDEpts, !is.element(KDEpts$cell, o$cell))

  # Extract predictor values for all background points
  biasKDE_all <- as.data.frame(extract(pred, KDEpts[,1]))
  bg <- rep("background", nrow(KDEpts))
  biasKDE_all <- cbind(bg, KDEpts, biasKDE_all)
  envSWD <- biasKDE_all[,-5]
  write.csv(envSWD, paste0("./output/envSWD/envSWD_",names[i],".csv"))

  if (nrow(biasKDE_all) > 10000){
    # Sample background points weighted by bias probability
    biasSWD <- biasKDE_all[sample(seq(1:nrow(biasKDE_all)),
                                  size=10000, 
                                  replace=F, 
                                  prob=biasKDE_all[,"prob"]),
                           c(1:4,6:ncol(biasKDE_all))]

    write.csv(biasSWD, paste0("./output/biasSWD/biasSWD_",names[i],".csv"))

  } else {
    print (paste0(names[i], " has fewer than 10000 background points"))
    n <- round(nrow(biasKDE_all)*.8, digits = 0)

    biasSWD <- biasKDE_all[sample(seq(1:nrow(biasKDE_all)), 
                                  size=n, 
                                  replace=F, 
                                  prob=biasKDE_all[,"prob"]),
                           c(1:4,6:ncol(biasKDE_all))]

    write.csv(biasSWD, paste0("./output/biasSWD/biasSWD_",names[i],".csv"))

  }
}

##