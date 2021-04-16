# Nitrogen deposition effects on Swiss butterfly richness

This repository contains all the materials needed to reproduce the analyses in:

*Roth, T., Kohli, L., Rihm, B., Meier, R. and Amrhein, V. (2021), Negative effects of nitrogen deposition on Swiss butterflies. Conservation Biology. Accepted Author Manuscript. https://doi.org/10.1111/cobi.13744*

An earlier version of the Manuscript is also available as a preprint from https://doi.org/10.1101/2020.07.10.195354

## Introduction

In this study we investigated how nitrogen (N) deposition may affect species richness and abundance in butterflies. We started with reviewing the literature and found that vegetation parameters might be as important as climate and habitat variables in explaining variation in butterfly species richness. It thus seems likely that increased N deposition indirectly affects butterfly communities via its influence on plant communities. To test this prediction, we analyzed data from the [Swiss biodiversity monitoring program](https://en.wikipedia.org/wiki/Biodiversity_Monitoring_Switzerland) surveying species diversity of vascular plants and butterflies in 383 study sites. Using traditional linear models and structural equation models, we found that high N deposition was consistently linked to low butterfly diversity, suggesting a net loss of butterfly diversity through increased N deposition. At low elevations, N deposition may contribute to a reduction in butterfly species richness via microclimatic cooling due to increased plant biomass. At higher elevations, negative effects of N deposition on butterfly species richness may also be mediated by reduced plant species richness. In most butterfly species, abundance was negatively related to N deposition, but the strongest negative effects were found for species of conservation concern. 

## Content of the repository

The repository contains the following folders.

### data

Folder that contains the data used in the BDM study.

- [butterflies.csv](data/butterflies.csv): List of species with the number of sites a species was recorded.

- [raw-data.csv](data/raw-data.csv): A table with the raw data of all analyzed BDM sites including dependent and predictor variables.  
- [rec.RData](data/rec.RData): RData-File that contains the sites x species matrix with the number of observed individuals in each cell. The matrix contains only the species that were recorded on at least 20 sites.
- [TABLE_1-variable_description.xlsx](data/TABLE_1-variable_description.xlsx): A table with a  description of all variables in [raw-data.csv](data/raw-data.csv). This table is also given in the manuscript.

### div

Folder with [setting_generic_model.xlsx](div/setting_generic_model.xlsx): Excel file that contains the settings to produce the path diagrams with the results from the structural equation models. This file will be used by the R-script that analyses the data using structural equation models.

### literature_review

Folder that contains material from the literature review literature on variables used to explain spatial variation in butterfly species richness:

- [S1-Webofscience_Search_Setting.png](literature_review/S1-Webofscience_Search_Setting.png): Screenshot of the web of science search setting. This is Appendix S1 of the manuscript.
- [S2-Result_of_review.xlsx](literature_review/S2-Result_of_review.xlsx): Excel File with the results of the literature review.This is Appendix S2 of the manuscript.

### R

- [Analyses-BDM-linearmodels.R](R/Analyses-BDM-linearmodels.R): R-script to perform the described analyses based on classical linear models.
- [Analyses-BDM-SEM.R](R/Analyses-BDM-SEM.R): R-script to perform the described analyses based on structural equation models.
- [Analyses-BDM-single species models.R](R/Analyses-BDM-single species models.R): R-script to perform the single species analyses. 
- [Analyses-literaturereview.R](R/Analyses-literaturereview.R): R-script to analyze the data from the literature review. 
- [Pairs-plot.R](R/Pairs-plot.R): R-Skript to produce the matrix of scatterplots between all predictor variables as given in Appendix S3 of the manuscript.
- [Prepare-raw-data.R](R/Prepare-raw-data.R): R-Skripts to prepare the raw data of the BDM analyses. The scripts exports the relevant data from the BDM data-base and also compiles the predictor variables from other resources. See description in the manuscript for further information.

### Results

Folder that contains figures and tables with key results of the analyses. All the files in this folder are produced by on of the R-Skripts in folder [R](R). 

