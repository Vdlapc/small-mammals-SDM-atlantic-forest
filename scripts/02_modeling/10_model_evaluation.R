# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      10_model_evaluation.R
# Description: Calculate AUC, weighted AUC, TSS and CBI for each model replicate. Filter valid replicates (wAUC >= 0.5, TSS >= 0.0, CBI >= 0.4). Average valid maps weighted by CBI per species/scenario.
# Stage:       2 - Modeling | Model Evaluation & Ensemble
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: terra, xlsx, enmSdmX
# Input:        ./output/models/{scenario}/{species}/ (samplePredictions.csv, backgroundPredictions.csv, maxentResults.csv)
# Output:       ./output/evaluation/01_validation_summary.csv (.xlsx), 01_validation_average.csv (.xlsx), rep_toaverage.csv; ./output/models/{scenario}/{species}/{species}_avg.tif, _cbi.tif
# =============================================================================


### Models validation metrics (AUC and TSS)
### Average valid models

Sys.setenv(JAVA_HOME = "C:/Program Files/Java/latest/jre-1.8/bin/java.exe")


library(terra)
library(xlsx)
library(enmSdmX) #calcula tss e cbi


### Models validation metrics (AUC, TSS, CBI) ####
# For TSS and CBI values calculation "Write background predictions" has to be enabled in Maxent

# Empty list to store evaluation results per scenario
eval_summary <- list()

# Empty data frame for TSS and AUC results across all runs
eval_df <- as.data.frame(matrix(ncol = 8, nrow = 0))
colnames(eval_df)<-c("scenario","species","Replica", "Bin.Prob", "AUC", "wAUC", "TSS", "CBI")


# Climate scenarios to project
sc <- c("current","ssp126","ssp245") #,"ssp585")

### PATH to output data

for (k in 1:length(sc)) {

  # output folder
  # list directory path for folders
  out.dir <- list.files(paste0("./output/models/", sc[k]), full.names = TRUE)
  spp.name <- list.files(paste0("./output/models/", sc[k]), full.names = FALSE)

  # Calculate evaluation metrics for all species and replicates
  for (a in 1:length(spp.name)){ #a = especie
    # list output files
    path <- paste0(out.dir[a], "/")
    # List all replicate output files
    listout <- list.files(path, pattern="_samplePredictions.csv")
    listout <- sub("_samplePredictions.csv","",listout)

    ## Empty data frame for per-replicate evaluation metrics
    validation_general <- as.data.frame(matrix(ncol = 8, nrow = 0))
    colnames(validation_general)<-c("scenario","species","Replica", "Bin.Prob", "AUC", "wAUC", "TSS", "CBI")

    for (i in 1:length(listout)){

      sp <- listout[i]
      presence<-read.csv(paste(path,sp,"_samplePredictions.csv",sep=""))
      background<-read.csv(paste(path,sp,"_backgroundPredictions.csv",sep=""))

      # Extract logistic predictions at presences and background
      predPres <- presence$Logistic.prediction
      predBg <- background$Logistic

      # Read MaxEnt summary results table
      maxres <- read.csv(paste(path,"maxentResults.csv", sep = ""))
      auc <-maxres[maxres[,1]==sp,"Test.AUC"] # AUC from MaxEnt internal output
      thisTr<- maxres[maxres[,1]==sp,"Maximum.test.sensitivity.plus.specificity.Logistic.threshold"]
      thisTss <- enmSdmX::evalTSS(pres=predPres, contrast=predBg, thresholds = thisTr)
      thisAuc <- enmSdmX::evalAUC(pres=predPres, contrast=predBg)
      thisCbi <- enmSdmX::evalContBoyce(pres=predPres, contrast=predBg)

      # Combine all evaluation metrics into a data frame
      evaldf <- as.data.frame(sc[k])
      evaldf[2] <- spp.name[a]
      evaldf[3] <- sp
      evaldf[4] <- thisTr
      evaldf[5] <- auc
      evaldf[6] <- thisAuc
      evaldf[7] <- thisTss
      evaldf[8] <- thisCbi
      colnames(evaldf) <- c("scenario","species","Replica", "Bin.Prob", "AUC", "wAUC", "TSS", "CBI")

      # Append replicate metrics to the full results table
      validation_general <- rbind(validation_general,evaldf)
    }

    eval_summary[[a]] <- validation_general
    # Collapse list into a single data frame
    eval_scenario <- do.call(rbind,eval_summary)
  }

  eval_df <- rbind(eval_df,eval_scenario)

} # end of loop for scenarios


### summary evaluation metrics data for all species and scenarios

# Flag replicates as include/remove based on AUC, TSS and CBI thresholds (>= 0.50),  TSS (>=0.0) and CBI (>= 0.4)
eval_df$decision <- ifelse(eval_df$wAUC >= 0.5 & eval_df$TSS >= 0.0 & eval_df$CBI >= 0.4, "include", "remove")

# Export full evaluation summary
write.csv(eval_df, file = "./output/evaluation/01_validation_summary.csv")
write.xlsx(eval_df, file = "./output/evaluation/01_validation_summary.xlsx", sheetName = "Sheet1", showNA = FALSE)


# Calculate averaged metrics for valid replicates only

# Filter to valid replicates only
values_toaverage <- subset(eval_df, grepl("include", eval_df$decision), select = c("scenario","species","Replica", "Bin.Prob", "AUC", "wAUC", "TSS", "CBI"))

# Compute mean evaluation metrics per species and scenario
metric_average <- aggregate(values_toaverage[,4:8], by = list(values_toaverage$species, values_toaverage$scenario), FUN = mean)
colnames(metric_average) <- c("species","scenario", "Bin.Prob", "AUC", "wAUC", "TSS", "CBI")

# Export averaged metrics
write.csv(metric_average, file = "./output/evaluation/01_validation_average.csv")
write.xlsx(metric_average, file = "./output/evaluation/01_validation_average.xlsx", sheetName = "Sheet1", showNA = FALSE)

### Averaged maps
# Identify valid replicate raster files for averaging
replicates_toaverage <- subset(eval_df, grepl("include", eval_df$decision), select = c(scenario,species,Replica,CBI))
sc_id <- replicates_toaverage$scenario
sp_id <- replicates_toaverage$species
rep_id <- replicates_toaverage$Replica
rep_cbi <- replicates_toaverage$CBI

replicates_toaverage$ID <- gsub("species_", "", replicates_toaverage$Replica)
replicates_toaverage$ID <- as.numeric(replicates_toaverage$ID)
replicates_toaverage$ID <- replicates_toaverage$ID + 1
replicates_toaverage$ID <- paste0("_", replicates_toaverage$ID, ".tif")

# Export list of valid replicate files to be averaged
write.csv(replicates_toaverage, file = "./output/evaluation/rep_toaverage.csv")


### generate averaged maps per species ####

# Get unique species and scenarios with valid replicates
spp <- as.vector(unique(replicates_toaverage$species))
sc <- as.vector(unique(replicates_toaverage$scenario))

sc <- c("current","ssp126","ssp245","ssp585")


for (k in 1:length(sc)) {

  for (j in 1:length(spp)){

    # Build path to model output folder
    path <- paste0("./output/models/",sc[k], "/", spp[j], "/")
    sdm_files <- subset(replicates_toaverage,
                        grepl(spp[j], replicates_toaverage$species) &
                          grepl (sc[k], replicates_toaverage$scenario),
                        select = ID)

    sdm <- paste0(path,sdm_files$ID)
    # Stack valid replicate maps
    sdmStack <- rast(sdm)

    # Simple mean of valid replicates
    sdm_avg <- mean(sdmStack)

    # Simple mean of valid replicatess by CBI
    cbi <- subset(replicates_toaverage, grepl(spp[j], replicates_toaverage$species) &
                    grepl (sc[k], replicates_toaverage$scenario),select = CBI)
    cbi.v <- cbi[,1]
    sdm_cbi <- terra::weighted.mean(sdmStack,cbi.v)

    # Export averaged and CBI-weighted maps
    writeRaster(sdm_avg, filename = paste0(path,spp[j],"_avg.tif"), overwrite=TRUE)
    writeRaster(sdm_cbi, filename = paste0(path,spp[j],"_cbi.tif"), overwrite=TRUE)
  }

} # end of loop for scenarios