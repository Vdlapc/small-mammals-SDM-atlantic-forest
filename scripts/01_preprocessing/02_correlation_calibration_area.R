# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      02_correlation_calibration_area.R
# Description: Evaluate correlation among predictor variables across the study area using Pearson correlation matrix. Used to guide variable pre-selection before VIF analysis.
# Stage:       1 - Preprocessing | Variable Correlation
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: terra, xlsx
# Input:        ./output/predictors/current/cropped/*.tif
# Output:       ./output/correlacao_area_estudo/correl_area_estudo.csv (.xlsx)
# =============================================================================


## mask raster predictors for building the models (calibration area) using mcp shape for each species

library(terra)

# Load predictor layers

# Load WorldClim layers cropped in script 01
bio_folder = "./output/predictors/current/cropped/"
bio_path <-list.files(path = bio_folder, patter='*.tif$')
bio_path
bio_files <- paste(bio_folder,bio_path, sep="")
bio_files
bio <- rast(bio_files)
plot(bio[[2]])

# Load species occurrence data
pts<- read.csv("./data/pts/SpeciesRecords_semoutlier.csv")
head(pts)
pts$scientificName <- gsub(" ", "_", pts$scientificName)
head(pts$scientificName)
speciesName <- unique(pts$scientificName)

# create shape file from pts
xy <- vect(pts, crs = "EPSG:4326", geom = c("x", "y"))
plot(xy)

# Build Minimum Convex Polygon (MCP) per species
mcp <- convHull(xy, "scientificName")
plot(mcp)

# buffer mcp 200 km
b <-buffer(mcp, 200000, quadsegs=10)
plot(b)

AMS <- vect("./shapes/AMS_ecoregions.shp", crs = "EPSG:4326")
plot(AMS)

AMS <- st_read("./shapes/AMS_ecoregions.shp")
plot(AMS)

AMS <- AMS[1]


# Fix invalid geometries
valid_geometries <- AMS[terra::is.valid(AMS)]
invalid_geometries <- AMS[!terra::is.valid(AMS)]

# Dissolve layer
dissolved_valid_geometries <- aggregate(valid_geometries)
plot(dissolved_valid_geometries)

# Clip buffer to land (remove ocean areas)
b_AMS <- crop(b,dissolved_valid_geometries)
plot(b_AMS)

b <- b_AMS

# Save MCP + buffer per species as shapefile
species_names <- unique(pts$scientificName)  # Species list

# Create output directory for shapefiles
dir.create("./output/mcp_shp_buffer_AMS/", recursive = TRUE, showWarnings = FALSE)

# Loop to save each species MCP with buffer as shapefile
for (species in species_names) {
  b_species <- b[b$scientificName == species, ]

  # Define output filename
  file_name <- paste0("./output/mcp_shp_buffer_AMS/", species, ".shp")

  # Save as shapefile
  writeVector(b_species, filename = file_name, overwrite = TRUE)
}

# Save MCP without buffer per species as shapefile
species_names <- unique(pts$scientificName)  # Species list

# Create output directory for shapefiles
dir.create("./output/mcp_shp_buffer_AMS/", recursive = TRUE, showWarnings = FALSE)

# Loop to save each species MCP without buffer as shapefile
for (species in species_names) {
  mcp_species <- mcp[mcp$scientificName == species, ]

  # Define output filename
  file_name <- paste0("./output/mcp_shp_sem_buffer/", species, ".shp")

  # Save as shapefile
  writeVector(mcp_species, filename = file_name, overwrite = TRUE)
}


# Loop to crop predictors to each species calibration area
# i: loop index over species
# iterates from 1 to length(b)

for (i in 1:length(b)){
   v <- b[i]
   c <- crop(bio,v)
   m <- mask(c,v)
   id <- v$scientificName
   out.dir <- paste0("./output/predictors/sps/", id, "/")
   dir.create(out.dir)
   writeRaster(m, paste0(out.dir,names(m),".tif"))
 }