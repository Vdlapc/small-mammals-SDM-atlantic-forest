# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      12_richness_maps.R
# Description: Stack binary distribution maps for all species per scenario and calculate species richness by summing presence layers. Output includes total richness and richness masked to the calibration area (Atlantic Forest).
# Stage:       3 - Analysis | Species Richness Maps
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
# Input:        ./output/binary_maps/{scenario}/{species}_dist_1NA.tif, ./data/shapes/MA/bosque_atlantico_limit.shp
# Output:       ./output/richness/{scenario}.tiff, {scenario}_cal.tiff, {scenario}_cal1NA.tiff
# =============================================================================


### Richness from binary distribution raster

library(terra)


mask <- rast("./output/predictors/wc21/current/cropped/wc2.1_30s_bio_1.tif")
mask <- project(mask, "EPSG:4326")
plot(mask)

cal <- vect("./data/shapes/MA/bosque_atlantico_limit.shp", crs = "EPSG:4326")
plot(cal)

cal.r <- rasterize(cal, mask, background = 0, touches = TRUE)
plot(cal.r)

# Get scenario names from output directory
sc <- list.files("./output/binary_maps/", full.names = FALSE)
sc <- sc[4]

for (k in 1:length(sc)) {

  # List binary distribution maps for this scenario
  spp.name <- list.files(paste0("./output/binary_maps/", sc[k], "/"), pattern = '*_dist_1NA.tif$', full.names = FALSE)

  # Initialise stack with the study area raster template (1 for presence / 0 background)
  r <- mask #raster cortado no bbox

  for (i in 1:length(spp.name)){
    dist.path <- paste0("./output/binary_maps/", sc[k],"/", spp.name[i])
    bin <- rast(dist.path)

    bin <- resample(bin, cal.r, method = "near")

    writeRaster(bin, filename= paste0("./output/intermediarios/", sc[k], "/", spp.name[i]), overwrite=T)
    gc()  # free memory  # free memory after saving to disk
    }
}


############## loop soma binarios ############
for (k in 1:length(sc)) {

  # List binary distribution maps for this scenario
  spp.name2 <- list.files(paste0("./output/intermediarios/", sc[k], "/"), pattern = '*_dist_1NA.tif$', full.names = FALSE)
  #spp.name2 <- spp.name2[1:3]


for (j in 1:40){

  bin_inter <- paste0("./output/intermediarios/", sc[k] ,"/", spp.name2[j])  # "./output/intermediarios/current_species_Akodon_cursor_dist_1NA.tif"
  bin_inter <- rast(bin_inter)

  r<- mask
  r <- c(r, bin_inter)

  #gc()

  r1 <- r

}

for (j in 41:80){

    bin_inter <- paste0("./output/intermediarios/", sc[k] ,"/", spp.name2[j])  # "./output/intermediarios/current_species_Akodon_cursor_dist_1NA.tif"
    bin_inter <- rast(bin_inter)

    r <- c(r, bin_inter)

    #gc()

    r2 <- r

}


  for (j in 81:length(spp.name2)){

    bin_inter <- paste0("./output/intermediarios/", sc[k] ,"/", spp.name2[j])  # "./output/intermediarios/current_species_Akodon_cursor_dist_1NA.tif"
    bin_inter <- rast(bin_inter)

    r <- c(r, bin_inter)

    gc()  # free memory

    r3 <- r

  }

  r1 <- r1[[-1]]
  r2 <- r2[[-1]]
  r3 <- r3[[-1]]

  r_final <-c(r1,r2,r3)
  all <- sum(r_final, na.rm = TRUE)

  writeRaster(all, filename= paste0("./output/richness/", sc[k], ".tiff"), overwrite=T)

  all.cal <- all*cal.r #0 e 1
  writeRaster(all.cal, filename= paste0("./output/richness/", sc[k], "_cal.tiff") , overwrite=T)

  maskNA <- all.cal/all.cal
  all.cal.mask <- all.cal * maskNA #so 1
  writeRaster(all.cal.mask, filename= paste0("./output/richness/", sc[k], "_cal1NA.tiff"), overwrite=T)

  rm(r)
  rm(r1)
  rm(r2)
  rm(r3)
  rm(r_final)
 }