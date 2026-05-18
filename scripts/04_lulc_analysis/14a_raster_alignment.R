# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      04a_raster_alignment.R
# Description: Reproject and align the species richness raster to match the
#              spatial reference of the Atlantic Spatial landscape metrics
#              (CRS, resolution, extent). Tests bilinear vs. nearest-neighbor
#              resampling methods and aggregation factors (4x and 10x).
# Stage:       4 - LULC Analysis | Raster Alignment & Reprojection
#
# Authors:
#   - Valéria Dallapícula
#
# MSc thesis in Animal Biology | UFES
# Date: May 2025
#
# Dependencies: terra
# Input:  ./data/richness/richness_cropMA.tif
#         ./data/atlantic_spatial/*.tif  (landscape metrics from Atlantic Spatial)
# Output: ./output/lulc/rich_proj_bi.tif
#         ./output/lulc/rich_proj_bi_round.tif
#         ./output/lulc/rich_proj_near.tif
#         ./output/lulc/narmT/rich_proj_near_T.tif
# =============================================================================

library(terra)

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
dir_metrics  <- "./data/atlantic_spatial/"
dir_richness <- "./data/richness/"
dir_out      <- "./output/lulc/"
dir_out_T    <- "./output/lulc/narmT/"

dir.create(dir_out,  recursive = TRUE, showWarnings = FALSE)
dir.create(dir_out_T, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Load reference metric raster (patch area — used as alignment template)
# -----------------------------------------------------------------------------
metrica <- rast(file.path(dir_metrics, "042_atlantic_spatial_forest_vegetation_patch_area.tif"))
plot(metrica)

# Load richness raster (cropped to Atlantic Forest)
rich <- rast(file.path(dir_richness, "richness_cropMA.tif"))

# -----------------------------------------------------------------------------
# Step 1 — Aggregate metric raster to coarser resolutions
# Aggregation factor 4  -> ~120 m pixels
# Aggregation factor 10 -> ~300 m pixels
# -----------------------------------------------------------------------------
metrica_agg_04 <- aggregate(metrica, fact = 4, fun = "modal")
writeRaster(metrica_agg_04, file.path(dir_out, "042_agg_04.tif"), overwrite = TRUE)

metrica_agg_10 <- aggregate(metrica, fact = 10, fun = "modal")
writeRaster(metrica_agg_10, file.path(dir_out, "042_agg_10.tif"), overwrite = TRUE)

# -----------------------------------------------------------------------------
# Step 2 — Reproject richness raster to match aggregated metric CRS + extent
# Two methods compared:
#   (i)  bilinear interpolation + round (preserves gradients, integer counts)
#   (ii) nearest-neighbor (preserves discrete values without interpolation)
# -----------------------------------------------------------------------------
rich_proj_bi       <- project(rich, metrica_agg_04, method = "bilinear")
rich_proj_bi_round <- round(rich_proj_bi)
rich_proj_near     <- project(rich, metrica_agg_04, method = "near")

writeRaster(rich_proj_bi,       file.path(dir_out, "rich_proj_bi.tif"),       overwrite = TRUE)
writeRaster(rich_proj_bi_round, file.path(dir_out, "rich_proj_bi_round.tif"), overwrite = TRUE)
writeRaster(rich_proj_near,     file.path(dir_out, "rich_proj_near.tif"),     overwrite = TRUE)

# Check alignment between aggregated metric and reprojected richness
list(
  CRS        = crs(metrica_agg_04) == crs(rich_proj_near),
  Extent     = ext(metrica_agg_04) == ext(rich_proj_near),
  Resolution = all(res(metrica_agg_04) == res(rich_proj_near)),
  Alignment  = compareGeom(metrica_agg_04, rich_proj_near, stopOnError = FALSE)
)

# -----------------------------------------------------------------------------
# Step 3 — Reproject richness using metric aggregated with na.rm = TRUE
# na.rm = TRUE fills edge cells that would otherwise become NA during aggregation
# -----------------------------------------------------------------------------
metrica_T        <- rast(file.path(dir_out_T, "002_agg_04_T.tif"))
rich_proj_near_T <- project(rich, metrica_T, method = "near")

# Visual comparison: default vs. na.rm = TRUE
par(mfrow = c(1, 2))
plot(rich_proj_near,   main = "Richness — near (default)")
plot(rich_proj_near_T, main = "Richness — near (na.rm = TRUE)")

writeRaster(rich_proj_near_T, file.path(dir_out_T, "rich_proj_near_T.tif"), overwrite = TRUE)
