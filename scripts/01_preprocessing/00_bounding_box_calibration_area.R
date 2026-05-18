# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      00_bounding_box_calibration_area.R
# Description: Define the study area bounding box and calibration area using occurrence points or a shapefile. 
# Applies a 200 km buffer to account for dispersal limitations.
# Stage:       1 - Preprocessing | Study Area Definition
#
# Authors:
#   - Original scripts: Msc. Bruno Evaldt and Dra. Ana Carolina Loss (INMA/UFES)
#   - Scientific supervision: Dra. Ana Carolina Loss (INMA/UFES)
#   - Adaptation & implementation: Valéria Dallapícula
#
# Adapted from scripts developed during MSc thesis in Animal Biology (UFES)
# Original development: 2023-2025
#
# Dependencies: terra, sf
# Input:        ./data/pts/SpeciesRecords.csv  OR  ./data/shapes/calibra.shp
# Output:       ./data/shapes/bb.shp, ./data/shapes/bb2.shp
# =============================================================================

library(usdm)
library(dismo)
library(terra)
library(ENMeval)
library(xlsx)
library(enmSdmX)
library(dplyr)
library(sf)
library(spData)
library(tmap)
library(tmaptools)


library(terra)

# read pts
pts<- read.csv("./data/pts/SpeciesRecords.csv")
head(pts)

# create shape file from pts
xy <- vect(pts, crs = "EPSG:4326", geom = c("x", "y"))
plot(xy)


# make poligon around points
mcp <- convHull(xy)
#mcp_sp <-convHull(xy, "scientificName")
plot(mcp)

# 200 km buffer: limits future dispersal area and reduces overprediction in projections
b <-buffer(mcp, 200000, quadsegs=10)
plot(b)

# make bounding box vector around buffer area to clip predictors
bb <-vect(ext(b)) # ext(b): retrieves spatial extent to create the bounding box vector
plot(bb)
writeVector(bb, "./data/shapes/bb.shp", overwrite = TRUE, options = "ENCODING=UTF-8")


## Alternative: use an existing shapefile (e.g. from QGIS) to define the bounding box
# read shape
pol <- vect("./data/shapes/calibra.shp", crs = "EPSG:4326")
plot(pol)

# buffer mcp 200 km

b2 <-buffer(pol, 200000, quadsegs=10)
plot(b2)
# make bounding box vector around buffer area to clip predictors
bb2 <-vect(ext(b2))
plot(bb2)
writeVector(bb2, "./data/shapes/bb2.shp", overwrite = TRUE, options = "ENCODING=UTF-8")