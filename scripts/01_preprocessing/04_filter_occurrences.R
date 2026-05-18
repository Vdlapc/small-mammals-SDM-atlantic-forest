# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      04_filter_occurrences.R
# Description: Filter occurrence records: remove points with no environmental data (NA), 
# keep only one record per raster cell (spatial thinning), and flag species with fewer than 3 records.
# Stage:       1 - Preprocessing | Occurrence Filtering & Thinning
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
# Input:        ./output/predNA/{species}_predNA.tif, ./data/pts/speciesRecords_model.csv
# Output:       ./output/pts_thin/xy_{species}.csv, ./output/ptsNA/ptsNA_{species}.csv
# =============================================================================


### Check for occurrence records with no data for any predictor
### Keep only one record per cell

library(terra)

## predictors NA file
pred_folder = paste0("./output/predNA/")
pred_path <-list.files(path = pred_folder, patter='*.tif$')
pred_files <- paste(pred_folder,pred_path, sep="")

names <- gsub("./output/predNA/", "", pred_files)
names <- gsub("_predNA.tif", "", names)
#names <- gsub("_", " ", names)
names

# Load occurrence data
xy_all<- read.csv("./data/pts/speciesRecords_model.csv")
#xy_all$sp <- gsub(" ", "_", xy_all$sp)

xy_all[1,]
xy_all[,1]
xy_all[xy_all$scientificName=="Akodon_cursor",]


for (i in 1:length(pred_files)){
  predNA <- rast(pred_files[i])
  xy <- xy_all[xy_all$scientificName==names[i],]
  pts <- vect(xy, crs = "epsg:4326", geom = c("x", "y"))

  pts$mask <- extract(predNA, pts)[,2]
  pts$cell <- cells(predNA, pts)[,2]
  pts <- pts[!duplicated(pts$cell),] # keep only one record per raster cell (spatial thinning)

  pts_out <- pts[is.na(pts$mask), ]
  ptsNA <- as.data.frame(pts_out)
  sp.name <- names[i]
  file_name <- paste0("./output/ptsNA/ptsNA_", sp.name, ".csv")
  write.csv(ptsNA, file_name, fileEncoding = "UTF-8")

  pts <- pts[!is.na(pts$mask),] # remove occurrences with no predictor value
  coords <- crds(pts)
  pts_xy <- as.data.frame(pts) # occurrences with environmental data
  pts_xy <- cbind(pts_xy,coords)


  species_less_than_3 <- c()

  if (nrow(pts_xy) >= 3) {
    # Se o número de registros for maior ou igual a 3, salva o arquivo
    file_name <- paste0("./output/pts_thin/xy_", sp.name, ".csv")
    write.csv(pts_xy, file_name, fileEncoding = "UTF-8")
  } else {
    # fewer than 3 records: flag species, do not model
    species_less_than_3 <- c(species_less_than_3, sp.name)
    message(paste0(sp.name, " has less than 3 records. Not to be modeled."))
  }

  # Export species with fewer than 3 records
  if (length(species_less_than_3) > 0) {
    write.csv(species_less_than_3, "./output/species_less_than_3.csv", row.names = FALSE, quote = FALSE)
    message("Species with less than 3 records saved in 'species_less_than_3.csv'.")
  }

   #
  # Alternative simpler condition (kept for reference):
   # file_name <- paste0("./output/pts_thin/xy_", sp.name, ".csv")
 # } else {
  #  paste0(sp.name, " has less than 3 records. Not to be modeled.")

  }