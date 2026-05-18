# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      08_feature_class_selection.R
# Description: Tune MaxEnt feature class (L, LQ, LQH) and regularization multiplier (1-3) using ENMeval with random k-fold partitioning. Best model selected by minimum AICc.
# Stage:       2 - Modeling | MaxEnt Parameter Tuning (ENMeval)
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: ENMeval, terra, rJava, ecospat
# Input:        ./output/xySWD/xySWD_{species}.csv, ./output/biasSWD/biasSWD_{species}.csv
# Output:       ./output/Fclass_best/ENMeval_best_{species}.csv, ./output/Fclass_results/ENMeval_evalResults_{species}.csv
# =============================================================================


# selecting feature class

library(ENMeval)
library(terra)
library(rJava)
library(ecospat)



names <- list.files("./output/biasSWD/")
names <- gsub("biasSWD_", "", names)
names <- gsub(".csv", "", names)
names

species_not_run <- c()
# import occurrence SWD file

for (i in 1:length(names)){

  # occurrence SWD file
  pts.file <- paste0("./output/xySWD/xySWD_", names[i], ".csv")
  xySWD <- read.csv(pts.file)
  xySWD <- xySWD[,4:ncol(xySWD)]

  # background SWD file
  bg.file <- paste0("./output/biasSWD/biasSWD_", names[i], ".csv")
  bgSWD <- read.csv(bg.file)
  bgSWD <- bgSWD[,4:ncol(bgSWD)]

  if (nrow(xySWD) >= 5){
    eval <- ENMevaluate(occs = xySWD, bg = bgSWD, parallel = TRUE, numCores = 3,
                        tune.args = list(fc = c("L", "LQ", "LQH"), rm = 1:3),
                        algorithm = "maxent.jar", partitions = "randomkfold")

    # fc = c("L", "LQ", "H", "LQH", "LQHP", "LQHPT"), rm = 1:3)
    # but common and recommended settings here are c(“L”, “LQ”, “LQH”). see Elith et al. 2011
    # RMvalues .-> A smoothing parameter. The higher the number the smoother your model.
    # Low values can lead to overfitting and low transferability to other times and spaces.
    # lower RM values increase the risk of overfitting

    bestmod <- which(eval@results$AICc==min(eval@results$AICc, na.rm = TRUE))
    f <- eval@results[bestmod,]
    f[1:2]

    write.csv(f, paste0("./output/Fclass_best/ENMeval_best_", names[i], ".csv"))
    write.csv(eval@results, paste0("./output/Fclass_results/ENMeval_evalResults_", names[i], ".csv"))

  } else {

    species_not_run <- c(species_not_run, names[i])
    write.csv(species_not_run, paste0("./output/species_not_run/less5_", names[i], ".csv"))
    }
}

##