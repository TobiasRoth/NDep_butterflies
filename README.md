# Nitrogen deposition effects on Swiss butterfly richness

This repository contains the data and R-scripts to reproduce the results presented in the MS "Effects of nitrogen deposition on butterfly species richness on the landscape scale". In the manuscript we describe the results of a literature review that we conducted to compile a list with the relevant predictor variables that explained variation in butterfly species richness. We then compiled these predictor variables for the study plots of the [Biodiversity Monitoring Switzerland](https://en.wikipedia.org/wiki/Biodiversity_Monitoring_Switzerland) (BDM) program to compare the effect of N deposition on butterfly species richness  as compared to the effects of predictor variables  that are important according to the literature review.

The manuscript is under review with [Conservation Biology](https://conbio.onlinelibrary.wiley.com/journal/15231739) and available as a preprint from https://doi.org/10.1101/2020.07.10.195354. Please site it as 

Roth, Tobias, Lukas Kohli, Beat Rihm, Reto Meier, and Valentin Amrhein. ‘Effects of Nitrogen Deposition on Butterfly Species Richness on the Landscape Scale’. Preprint. Ecology, 12 July 2020. https://doi.org/10.1101/2020.07.10.195354.

The repository contains the following folders.

### data

Folder that contains the data used in the BDM study.

- [raw-data.csv](data/raw-data.csv): A table with the raw data of all analyzed BDM sites including dependent and predictor variables.  
- [TABLE_1-variable_description.xlsx](data/TABLE_1-variable_description.xlsx): A table with a  description of all variables in [raw-data.csv](data/raw-data.csv). This table is also given in the manuscript.

### div

Folder that contains the following files:

- [setting_generic_model.xlsx](div/setting_generic_model.xlsx): Excel file that contains the settings to produce the path diagrams with the results from the structural equation models. This data will be used by the R-script that analyses the data using structural equation models.

### literature_review

Folder that contains material from the literature review of  factors that explain butterfly species richness.

- [A1-Webofscience_Search_Setting.png](literature_review/A1-Webofscience_Search_Setting.png): Screenshot of the web of science search setting. This is Appendix A1 of the manuscript.
- [A2-Result_of_review.xlsx](leterature_review/A2-Result_of_review.xlsx): Excel File with the results of the literature review.This is Appendix A2 of the manuscript.

### MS

Current version of the manuscript. 

### R

- [Analyses-BDM-linearmodels.R](R/Analyses-BDM-linearmodels.R): R-script to perform the described analyses based on classical linear models.
- [Analyses-BDM-SEM.R](R/Analyses-BDM-SEM.R): R-script to perform the described analyses based on structural equation models.
- [Analyses-literaturereview.R](R/Analyses-literaturereview.R): R-script to analyze the data from the literature review. 
- [Pairs-plot.R](R/Pairs-plot.R): R-Skript to produce the matrix of scatterplots between all predictor variables as given in Appendix A3 of the manuscript.
- [Prepare-raw-data.R](R/Prepare-raw-data.R): R-Skripts to prepare the raw data of the BDM analyses. The scripts exports the relevant data from the BDM data-base and also compiles the predictor variables from other resources. See description in the manuscript for further information.

### Results

Folder that contains figures and tables with key results of the analyses. All the files in this folder are produced by on of the R-Skripts in folder [R](R). 

