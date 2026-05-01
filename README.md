# small-mammals-SDM-atlantic-forest
Ecological Niche Modeling (ENM) &amp; Spatial Analysis of Atlantic Forest Small Mammals: A pipeline to evaluate habitat suitability and the impacts of land use and land cover (LULC) change.


# Modelagem de Nicho Ecológico: Pequenos Mamíferos na Mata Atlântica

Este repositório contém o pipeline completo de análise de dados espaciais e modelagem preditiva desenvolvido durante meu Mestrado em Biologia Animal (UFES). O projeto foca na distribuição de pequenos mamíferos, utilizando integração de bases de dados globais e variáveis climáticas/ambientais.

## 🚀 Destaques Técnicos
* **Volume de Dados:** Processamento e limpeza de registros de ocorrência (GBIF, SpeciesLink e SALVE).
* **Stack Tecnológica:** R (tidyverse, sf, terra, biomod2).
* **Modelagem Preditiva:** Implementação do algoritmo MaxEnt via pacote `biomod2`.
* **Consenso de Cenários (Ensemble Forecasting):** Integração de múltiplos Modelos de Circulação Global (GCMs) para garantir a robustez das predições climáticas, mesmo com foco em cenários atuais.
* **Análise de Incerteza:** Avaliação da variabilidade entre diferentes projeções climáticas para filtrar áreas de alta concordância ambiental.
* **Análise Geoespacial:** Integração de camadas raster (WorldClim, MapBiomas) e vetoriais para análise de uso do solo.
* **Métricas de Performance:** Avaliação de modelos através de AUC, TSS e CBI, com análise de incerteza espacial.

## 📂 Estrutura do Repositório
* `/scripts`: Scripts R organizados por etapa (limpeza, modelagem, validação).
* `/data`: Metadados e fontes das camadas utilizadas.
* `/outputs`: Mapas de adequabilidade ambiental e gráficos de importância de variáveis.

## 🛠️ Metodologia e Workflow
1. **Tratamento de Dados:** Filtragem de outliers espaciais e limpeza taxonômica.
2. **Seleção de Variáveis:** Análise de correlação (VIF) e PCA para redução de dimensionalidade.
3. **Modelagem:** Execução de modelos de nicho com abordagem *ensemble forecasting*.
4. **Pós-processamento:** Geração de mapas de consenso e avaliação de incertezas entre algoritmos.

## 📈 Status do Projeto e Insights Preliminares
O pipeline atual permite cruzar os mapas de adequabilidade ambiental com camadas de uso e cobertura do solo (MapBiomas). 

* **Análise de Variáveis:** Identificação preliminar das classes de uso do solo que predominam em áreas de alta adequabilidade para pequenos mamíferos.
* **Work in Progress:** Refinamento das análises espaciais para quantificar a fragmentação e o impacto de borda na ocupação do habitat.
* **Objetivo:** Submissão de artigo científico focando na intersecção entre áreas de endemismo e dinâmica de uso do solo no bioma.

## 🤝 Créditos e Colaborações
* **Desenvolvimento Original:** Este pipeline foi adaptado e expandido a partir de scripts desenvolvidos por Bruno Evaldt.
* **Orientação Científica:** Dra. Ana Carolina Loss (INMA).
* **Autoria e Implementação:** Valéria Dallapícula.
