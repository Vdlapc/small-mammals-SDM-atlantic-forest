# =============================================================================
# ECOLOGICAL NICHE MODELING - Atlantic Forest Small Mammals
# MSc in Animal Biology | UFES
# =============================================================================
# Script:      05_glm_lulc.R
# Description: Fit a Poisson GLM to test the effect of land use and landscape
#              metrics on small mammal species richness in the Atlantic Forest.
#              Includes a dummy-coded model for land use classes (MapBiomas),
#              estimated richness per class, percentage differences relative to
#              the reference class, and result visualisation.
# Stage:       4 - LULC Analysis | GLM Modelling & Visualisation
#
# Authors:
#   - Valéria Dallapícula
#
# MSc thesis in Animal Biology | UFES
# Date: May 2025
#
# Dependencies: ggplot2, knitr, performance
# Input:  ./output/lulc/narmT/values_df.csv
# Output: GLM summaries printed to console; plots rendered interactively
# =============================================================================

library(ggplot2)
library(knitr)
library(performance)

# -----------------------------------------------------------------------------
# Load sampled data
# -----------------------------------------------------------------------------
dados <- read.csv("./output/lulc/narmT/values_df.csv")
head(dados)

# -----------------------------------------------------------------------------
# Full Poisson GLM — richness ~ all landscape metrics + land use class
# -----------------------------------------------------------------------------
modelo <- glm(
  richness_cropMA ~
    mapbiomas_brazil_af_trinacional_2020_af_lim_grouped_classes +
    atlantic_spatial_forest_vegetation_fragment_area_ha +
    atlantic_spatial_forest_vegetation_patch_area_ha +
    atlantic_spatial_forest_vegetation_morphology +
    atlantic_spatial_forest_vegetation_perimeter +
    atlantic_spatial_natural_vegetation_perimeter +
    atlantic_spatial_forest_vegetation_structural_connected_area +
    atlantic_spatial_natural_vegetation_structural_connected_area +
    roads_railways_af_lim_distance_outside +
    protected_areas +
    indigenous_territory +
    X501_atlantic_spatial_quilombola_territories_binary,
  data   = dados,
  family = poisson()
)

summary(modelo)

# Exploratory scatter plot: richness ~ land use class
ggplot(dados, aes(x = mapbiomas_brazil_af_trinacional_2020_af_lim_grouped_classes,
                  y = richness_cropMA)) +
  geom_point() +
  geom_smooth(method = "glm", method.args = list(family = "poisson"))

# -----------------------------------------------------------------------------
# Land use class model — Poisson GLM with land use class as a dummy variable
# Class 1 (Forest Vegetation) set as reference level
# -----------------------------------------------------------------------------
dados$mapbiomas_brazil_af_trinacional_2020_af_lim_grouped_classes <-
  factor(dados$mapbiomas_brazil_af_trinacional_2020_af_lim_grouped_classes)

dados$mapbiomas_brazil_af_trinacional_2020_af_lim_grouped_classes <-
  relevel(dados$mapbiomas_brazil_af_trinacional_2020_af_lim_grouped_classes, ref = "1")

modelo_classes <- glm(
  richness_cropMA ~ mapbiomas_brazil_af_trinacional_2020_af_lim_grouped_classes,
  family = poisson(),
  data   = dados
)

summary(modelo_classes)

# -----------------------------------------------------------------------------
# Interpret model coefficients: estimated richness per land use class
# Coefficients from modelo_classes summary
# -----------------------------------------------------------------------------
intercepto <- 3.470816

coeficientes <- c(
  "Forest Vegetation (ref)"  =  0.000000,
  "Natural Vegetation"       = -0.195116,
  "Forest Plantation"        =  0.155185,
  "Pasture"                  = -0.120302,
  "Temporary Crop"           = -0.285109,
  "Perennial Crop"           = -0.591618,
  "Urban Area"               =  0.176590,
  "Mining"                   = -0.162709,
  "Water"                    = -0.288244
)

# Estimated richness on the response scale (exp of linear predictor)
richness_estimated <- exp(intercepto + coeficientes)
richness_estimated

# Percentage difference relative to the reference class (Forest Vegetation)
pct_difference <- (richness_estimated - exp(intercepto)) / exp(intercepto) * 100
pct_difference

# -----------------------------------------------------------------------------
# Visualisation — Estimated richness per land use class
# -----------------------------------------------------------------------------
class_names <- names(coeficientes)
df_plot <- data.frame(
  Class    = factor(class_names, levels = class_names),
  Richness = as.numeric(richness_estimated)
)

ggplot(df_plot, aes(x = Class, y = Richness, fill = Class)) +
  geom_bar(stat = "identity") +
  labs(
    title = "Estimated species richness by land use class",
    x     = "Land use class",
    y     = "Estimated richness"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

# Percentage difference relative to Forest Vegetation
df_pct <- data.frame(
  Class      = factor(class_names, levels = class_names),
  Percentage = as.numeric(pct_difference)
)

ggplot(df_pct, aes(x = Class, y = Percentage, fill = Class)) +
  geom_bar(stat = "identity") +
  labs(
    title = "Percentage difference in richness relative to Forest Vegetation",
    x     = "Land use class",
    y     = "Difference (%)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

# -----------------------------------------------------------------------------
# Summary table of model coefficients
# -----------------------------------------------------------------------------
tabela <- data.frame(
  Class = c(
    "Intercept (Forest Vegetation — reference class)",
    "Class 0 (N/A)",
    "Natural Vegetation (class 2)",
    "Forest Plantation (class 3)",
    "Pasture (class 4)",
    "Temporary Crop (class 5)",
    "Perennial Crop (class 6)",
    "Urban Area (class 7)",
    "Mining (class 8)",
    "Water (class 9)"
  ),
  Estimate  = c(3.470816, 0.005536, -0.195116,  0.155185, -0.120302,
                -0.285109, -0.591618,  0.176590, -0.162709, -0.288244),
  Std_Error = c(0.001737, 0.005406,  0.010308,  0.009385,  0.007649,
                0.009628,  0.029450,  0.040394,  0.078106,  0.030078),
  Z_value   = c(1998.490,  1.024,   -18.929,    16.536,   -15.729,
                -29.612,   -20.089,    4.372,    -2.083,    -9.583),
  P_value   = c("< 2e-16", "0.3058", "< 2e-16", "< 2e-16", "< 2e-16",
                "< 2e-16", "< 2e-16", "1.23e-05", "0.0372",  "< 2e-16"),
  Significance = c("***", "N/A", "***", "***", "***", "***", "***", "***", "*", "***")
)

kable(tabela,
      col.names = c("Class", "Estimate", "Std. Error", "Z value", "p-value", "Significance"),
      caption   = "GLM coefficient table — richness ~ land use class (Poisson)")
