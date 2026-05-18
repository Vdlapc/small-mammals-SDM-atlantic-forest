# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      09b_maxent_future_scenarios.R
# Description: Project fitted MaxEnt models onto future climate scenarios (SSP126, SSP245, SSP585). 
# Handles column name standardization between present/future predictor layers.
# Stage:       2 - Modeling | MaxEnt — Future Scenarios
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: dismo, terra, tidyverse (Java: maxent.jar required)
# Input:        ./output/xySWD/, ./output/biasSWD/, ./output/Fclass_best/, ./output/predictors/wc21/{ssp}/
# Output:       ./output/models/{ssp}/{species}/*.tif
# =============================================================================


Sys.setenv(JAVA_HOME = "C:/Program Files/Java/latest/jre-1.8/bin/java.exe")


options(java.parameters = "-Xmx8g")

library(dismo)
library(terra)
library(tidyverse)

# lat/long for all species to be modeled
#spp.xy <- read.csv("./data/pts/SpeciesRecords_modelo.csv")
#spp.xy$sp <- gsub(" ", "_", spp.xy$sp)

# Get unique species names
#spp

# lat/long for all species to be modeled
spp.xy <- read.csv("./data/pts/SpeciesRecords_modelo.csv")
spp.xy$scientificName <- gsub(" ", "_", spp.xy$scientificName)
unique(spp.xy$scientificName)

names <- list.files("./output/Fclass_best/")
names <- gsub("ENMeval_best_", "", names)
names <- gsub(".csv", "", names)
names

spp.xy_filtrado <- spp.xy[spp.xy$scientificName %in% names, ]
spp.xy_filtrado$scientificName
unique(spp.xy_filtrado$scientificName)

spp.xy <- spp.xy_filtrado

# Get unique species names
spp <- unique(spp.xy$scientificName)
spp

# Climate scenarios to project
sc <- c("ssp126","ssp245","ssp585")

#for (j in 1:length(sc)) {

  for (j in 1:length(sc)) {
  # Predictor files for model projection
  pred.files <- list.files(paste0("./output/predictors/wc21/", sc[j], "/cropped/"), pattern = '*.tif$', full.names = TRUE)
  pred.all <- stack(pred.files)

  pred.names <- names(pred.all)
  pred.names <- gsub("(.*_2061.2080)(_*)", paste0("bio","\\2"), pred.names)
  names(pred.all) <- pred.names

  for (i in 1:length(spp)){

    #Output folder
    dir.name <- paste0("./output/models/", sc[j], "/", spp[i], "/")
    dir.create(dir.name)

    # Occurrence SWD data
    xy.path <- paste0("./output/xySWD/xySWD_",spp[i],".csv")
    pts <- read.csv(xy.path)
    pts <- pts[,6:length(pts)]
    #pts.v <- rep(1, nrow(pts))

    # Background SWD data
    env.path  <-paste0("./output/biasSWD/biasSWD_",spp[i],".csv")
    env <- read.csv(env.path)
    env <- env[,6:length(env)]
    #env.v <- rep(0,nrow(env))

    # Combine occurrence and background into SWD
    swd <- rbind(pts,env)

    colnames(swd) <- gsub("wc2.1_30s_", "", colnames(swd))


    #all.v <- c(pts.v,env.v)
    swd.v <- c(rep(1, nrow(pts)), rep(0,nrow(env)))

    # Subset predictors to match SWD variable names
    p.names <- colnames(swd)
    pred <- subset(pred.all, p.names)

    # MaxEnt arguments
    # Feature class from ENMeval tuning
    f.path <- paste0("./output/Fclass_best/ENMeval_best_",spp[i],".csv")
    f <- read.csv(f.path)
    fc <- f$fc

    if (fc =='L'){
      fclass <-c("linear=true","quadratic=false","hinge=false","product=false","threshold=false")
    } else {
      if (fc =='LQ'){
        fclass <-c("linear=true","quadratic=true","hinge=false","product=false","threshold=false")
      } else {
        fclass <-c("linear=true","quadratic=true","hinge=true","product=false","threshold=false")
      }
    }

    # Regularization multiplier from ENMeval tuning
    rm <-paste0("betamultiplier=",f$rm)

    args = c('randomseed=true',
             'outputformat=logistic',
             'replicatetype=crossvalidate',
             'replicates=5',
             #'threads=60',
             fclass,
             rm,
             'writebackgroundpredictions=true')


    # Fit MaxEnt model
    model <- maxent(x=swd, p=swd.v, path = dir.name, args)

    # Project MaxEnt model onto predictor layers
    p <- predict(object = model, x = pred, filename = dir.name,
                 na.rm = TRUE, format = 'GTiff', overwrite = TRUE, progress = 'text')
  }


} # end loop j for sc