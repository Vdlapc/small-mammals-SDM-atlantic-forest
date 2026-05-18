# small-mammals-SDM-atlantic-forest

**Ecological Niche Modeling & Spatial Analysis of Atlantic Forest Small Mammals**
*A pipeline to model habitat suitability and evaluate the impacts of land use and land cover (LULC) change on small mammal diversity.*

---

## 🇧🇷 Sobre o Projeto

Este repositório contém o pipeline completo de modelagem preditiva e análise de dados espaciais desenvolvido durante meu **Mestrado em Biologia Animal (UFES)**. O projeto modela a distribuição de pequenos mamíferos da Mata Atlântica, integrando dados de ocorrência de múltiplas bases globais (GBIF, SpeciesLink, SALVE) com variáveis bioclimáticas e métricas de paisagem.

O pipeline cobre desde o pré-processamento dos dados até a análise do impacto do uso do solo na riqueza de espécies, com projeções para cenários climáticos futuros (SSP126, SSP245, SSP585).

---

## 🚀 Technical Highlights

- **Data volume:** Occurrence records filtered, deduplicated and spatially thinned from GBIF, SpeciesLink and SALVE.
- **Stack:** R (`terra`, `dismo`, `ENMeval`, `usdm`, `sf`, `ggplot2`, `knitr`, `performance`).
- **MaxEnt via `dismo`:** Parameter tuning (feature class + regularization multiplier) with `ENMeval` using minimum AICc criterion.
- **Ensemble forecasting:** CBI-weighted averaging across 5-fold cross-validation replicates; replicates filtered by wAUC ≥ 0.5, TSS ≥ 0.0, CBI ≥ 0.4.
- **Uncertainty analysis:** Spatial variability evaluated across replicates and future GCM scenarios.
- **Geospatial analysis:** Integration of raster layers (WorldClim v2.1, MapBiomas, Atlantic Spatial) and vector layers; reprojection and alignment pipeline for multi-source data.
- **Performance metrics:** AUC, weighted AUC, TSS and CBI per replicate and species.
- **GLM (Poisson):** Species richness modelled as a function of LULC classes (MapBiomas) and landscape metrics (Atlantic Spatial dataset).

---

## 📂 Repository Structure

```
scripts/
├── 01_preprocessing/       # Study area definition, predictor cropping, occurrence filtering
├── 02_modeling/            # MaxEnt parameter tuning, bias correction, model fitting & evaluation
├── 03_analysis/            # Binary maps, species richness rasters, area calculations
├── 04_lulc_analysis/       # Raster alignment, landscape metric aggregation, GLM
```

---

## 🛠️ Methodology & Workflow

### 1 · Preprocessing (`01_preprocessing/`)
Definition of the study area (bounding box + 200 km MCP buffer per species). Cropping of WorldClim v2.1 bioclimatic layers to the calibration area. Pearson correlation analysis and spatial thinning of occurrence records (one record per raster cell). Masking of NA cells across all predictor layers.

### 2 · Modeling (`02_modeling/`)
Variable selection via VIF (< 10). Generation of a KDE-based bias file (QGIS) rescaled to [1, 100] for weighted background sampling. MaxEnt parameter tuning with `ENMeval` (feature classes L/LQ/LQH, regularization multipliers 1–3, minimum AICc). Model fitting with 5-fold cross-validation and projection onto current and future climate scenarios (SSP126, SSP245, SSP585). Model evaluation with AUC, TSS and CBI; CBI-weighted ensemble of valid replicates.

### 3 · Analysis (`03_analysis/`)
Conversion of continuous suitability maps to binary presence/absence using the Maximum TSS threshold, clipped to the species MCP + 200 km buffer. Stacking of binary maps to compute species richness rasters per scenario. Calculation of distribution area (km²) and percentage change between scenarios.

### 4 · LULC Analysis (`04_lulc_analysis/`)
Spatial alignment of the richness raster with Atlantic Spatial landscape metric layers (reprojection, resampling, aggregation — factor 4, ~120 m). Random sampling of 10,000 points across the raster stack. Poisson GLM modelling richness as a function of MapBiomas LULC classes and Atlantic Spatial landscape metrics (fragment area, patch area, morphology, perimeter, structural connectivity, roads, protected areas, indigenous and quilombola territories).

---

## 📈 Project Status

The pipeline is complete from data acquisition through GLM modelling. Preliminary results indicate that **forest vegetation** supports the highest estimated small mammal richness, with significant reductions in urban areas (−15%) and perennial crops (−45%) relative to native forest. Spatial refinement of fragmentation and edge-effect metrics is ongoing ahead of manuscript submission.

---

## 🤝 Credits & Collaboration

| Role | Person |
|---|---|
| ENM pipeline — original scripts | Bruno Evaldt |
| Scientific supervision | Dra. Ana Carolina Loss (INMA/UFES) |
| LULC analysis, adaptation & implementation | Valéria Dallapícula |

---

## 📦 Data Sources

| Dataset | Use |
|---|---|
| [WorldClim v2.1](https://www.worldclim.org/) | Bioclimatic predictors (current + SSP scenarios) |
| [GBIF](https://www.gbif.org/) / [SpeciesLink](https://specieslink.net/) / [SALVE](https://salve.icmbio.gov.br/) | Occurrence records |
| [MapBiomas](https://mapbiomas.org/) | Land use and land cover classes |
| [Atlantic Spatial](https://github.com/LEEClab/Atlantic_spatial) | Landscape metrics (fragment area, connectivity, roads, protected areas) |
