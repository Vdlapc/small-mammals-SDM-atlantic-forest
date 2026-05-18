# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      01_crop_predictors.R
# Description: Crop bioclimatic predictor layers (WorldClim) to the study area bounding box for both current and future climate scenarios.
# Stage:       1 - Preprocessing | Predictor Cropping
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
# Input:        ./data/shapes/bb.shp, WorldClim rasters (current and future SSP scenarios)
# Output:       ./output/predictors/current/cropped/*.tif, ./output/predictors/future/cropped/*.tif
# =============================================================================


install.packages('terra')
library(terra)


## 1. STUDY AREA   ####

study_area <- vect("./data/shapes/bb.shp", crs = "EPSG:4326")
#study_area<-project(study_area, "EPSG:4326") #WGS84
plot(study_area)
bb <- study_area
plot(bb)

## use extent of clipped example to create a bounding box to clip the predictors
# NOTE: clipping is faster than masking. Clipping everything before masking will speed up the process

# Load one layer to test the study area extent
r <- rast("./WorldClim_2024/wc2.1_30s_bio/wc2.1_30s_bio_2.tif")
plot(r)

#ex <- r[[1]]
#ex<-project(ex, "EPSG:4326") #WGS84

# Crop example layer to study area to verify extent
r_bb <- crop(r,bb) # crop raster to study area extent
plot(r_bb)

##   2. PREDICTORS      ####

## Current climate scenario ##
# Load WorldClim bioclimatic layers

bio_folder = "./WorldClim_2024/wc2.1_30s_bio/"

bio_path <-list.files(path = bio_folder, patter='*.tif$') #dá o nome do arquivo - lista todos os arquivos .tif dentro da pasta, o * significa que tem um texto antes que pode variar (antes do .asc), o $ sinaliza o final da 'frase' ("ancora no finaL")
bio_path
bio_files <- paste(bio_folder,bio_path, sep="") # build full file paths
bio_files
bio <- rast(bio_files) # load raster stack
bio # 19 variaveis climaticas - mapa mundi
plot(bio[[2]])


#### crop predictors using bb extent
bio_bb <- crop(bio,bb) # crop to study area bounding box
plot(bio_bb[[2]])

#### save as .ascii in the new folder
writeRaster(bio_bb, paste0("./output/predictors/current/cropped/",names(bio_bb),".tif")) #paste0 cola os nomes sem espaço entre eles

# using names(bio_bb) preserves variable names in output files
# stack() saves all layers together

## Future climate scenarios ##

bio_folder = "./WorldClim_2024/futuro/"

bio_path <-list.files(path = bio_folder, patter='*.tif$')
bio_path
bio_files <- paste0(bio_folder,bio_path)
bio_files
bio <- rast(bio_files)
plot(bio)
bio_bb <- crop(bio,bb)
plot(bio_bb)
writeRaster(bio_bb, paste0("./output/predictors/future/cropped/",names(bio_bb),".tif"))

#############33

# ssp1-2.6
#bio_bb <- crop(bio,bb)
#writeRaster(bio_bb, paste0("./output/predictors/wc21/ssp126/",names(bio_bb),".asc"))

# ssp2-4.5
bio <- rast("./data/wc21/miroc6_2_5/wc2.1_2.5m_bioc_MIROC6_ssp245_2061-2080.tif")
bio_bb <- crop(bio,bb)
writeRaster(bio_bb, paste0("./output/predictors/wc21/ssp245/",names(bio_bb),".tif"))

# ssp3-7.0
bio <- rast("./data/wc21/miroc6_2_5/wc2.1_2.5m_bioc_MIROC6_ssp370_2061-2080.tif")
bio_bb <- crop(bio,bb)
writeRaster(bio_bb, paste0("./output/predictors/wc21/ssp370/",names(bio_bb),".tif"))

# ssp5-8.5
bio <- rast("./data/wc21/miroc6_2_5/wc2.1_2.5m_bioc_MIROC6_ssp585_2061-2080.tif")
bio_bb <- crop(bio,bb)
writeRaster(bio_bb, paste0("./output/predictors/wc21/ssp585/",names(bio_bb),".tif"))

##