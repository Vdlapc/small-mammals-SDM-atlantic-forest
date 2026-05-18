# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      04b_metric_aggregation_sampling.R
# Description: Aggregate all Atlantic Spatial landscape metric rasters by a
#              factor of 4 (modal, na.rm = TRUE), stack them with the
#              reprojected richness raster, and extract a random sample of
#              points for GLM modelling.
# Stage:       4 - LULC Analysis | Metric Aggregation & Point Sampling
#
# Authors:
#   - Valéria Dallapícula
#
# MSc thesis in Animal Biology | UFES
# Date: May 2025
#
# Dependencies: terra
# Input:  ./data/atlantic_spatial/*.tif
#         ./output/lulc/narmT/rich_proj_near_T.tif
# Output: ./output/lulc/narmT/*_agg_04_T.tif  (aggregated metrics)
#         ./output/lulc/narmT/values_df.csv    (sampled points for GLM)
# =============================================================================

library(terra)

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
dir_metrics <- "./data/atlantic_spatial/"
dir_out_T   <- "./output/lulc/narmT/"

dir.create(dir_out_T, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Metric file list
# -----------------------------------------------------------------------------
metric_names <- c(
  "002_atlantic_spatial_grouped_classes",
  "006_atlantic_spatial_forest_vegetation_fragment_area",
  "042_atlantic_spatial_forest_vegetation_patch_area",
  "049_atlantic_spatial_forest_vegetation_morphology",
  "375_atlantic_spatial_forest_vegetation_perimeter",
  "377_atlantic_spatial_natural_vegetation_perimeter",
  "385_atlantic_spatial_forest_vegetation_structural_connected_area",
  "387_atlantic_spatial_natural_vegetation_structural_connected_area",
  "496_atlantic_spatial_roads_railways_distance",
  "497_atlantic_spatial_protected_areas_binary",
  "499_atlantic_spatial_indigenous_territories_binary",
  "501_atlantic_spatial_quilombola_territories_binary"
)

# Subset used for processing (metrics 3–12; first two processed separately)
metric_names_subset <- metric_names[3:12]

# -----------------------------------------------------------------------------
# Step 1 — Aggregate each metric raster by factor 4 (modal, na.rm = TRUE)
# modal aggregation preserves categorical/integer values
# na.rm = TRUE fills border cells that would otherwise become NA
# -----------------------------------------------------------------------------
for (name in metric_names_subset) {
  id       <- sub("_.*", "", name)                              # extract numeric ID prefix
  in_path  <- file.path(dir_metrics, paste0(name, ".tif"))
  out_path <- file.path(dir_out_T, paste0(id, "_agg_04_T.tif"))

  metrica <- rast(in_path)
  m_agg   <- aggregate(metrica, fact = 4, fun = "modal", na.rm = TRUE)

  writeRaster(m_agg, out_path, overwrite = TRUE)
  cat("Saved:", basename(out_path), "\n")
}

# -----------------------------------------------------------------------------
# Step 2 — Build raster stack (richness + all aggregated metrics)
# -----------------------------------------------------------------------------
raster_files <- list.files(dir_out_T, pattern = "\\.tif$", full.names = TRUE)
rasters      <- lapply(raster_files, rast)
raster_stack <- do.call(c, rasters)

plot(raster_stack)
names(raster_stack)

# -----------------------------------------------------------------------------
# Step 3 — Check valid pixels across all layers
# -----------------------------------------------------------------------------
# Per-layer valid pixel count
valid_per_layer <- sapply(1:nlyr(raster_stack), function(i) {
  global(raster_stack[[i]], fun = function(x) sum(!is.na(x)))[1, 1]
})
valid_per_layer

# Pixels valid across ALL layers simultaneously
valid_all_layers <- app(raster_stack, fun = function(...) all(!is.na(c(...))))
total_valid      <- global(valid_all_layers, fun = sum)[1, 1]
cat("Total pixels valid in all layers:", total_valid, "\n")

# -----------------------------------------------------------------------------
# Step 4 — Random point sampling for GLM
# Oversample then clean NAs to guarantee target sample size
# set.seed ensures reproducibility across runs
# -----------------------------------------------------------------------------
set.seed(42)

n_target       <- 10000
initial_sample <- 30000

points_sample <- spatSample(
  raster_stack,
  size      = initial_sample,
  method    = "random",
  na.rm     = FALSE,
  as.points = TRUE
)

values_df       <- as.data.frame(points_sample)
values_df_clean <- na.omit(values_df)

if (nrow(values_df_clean) < n_target) {
  warning("Fewer than 10,000 valid points after NA removal. Consider increasing initial_sample.")
} else {
  values_df_clean <- values_df_clean[sample(nrow(values_df_clean), n_target), ]
}

head(values_df_clean)
cat("Final sample size:", nrow(values_df_clean), "\n")

write.csv(values_df_clean,
          file      = file.path(dir_out_T, "values_df.csv"),
          row.names = FALSE)
