rm(list=ls(all=TRUE))

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Settings and load data----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Libraries
library(tidyverse)
library(readxl)
library(openxlsx)

# Read data
dat <- read_csv("data/raw-data.csv")
dat$ele2 <- dat$ele^2

# Load data from literature review
LR_studies <- read_excel("literature_review/S2-Result_of_review.xlsx", sheet = "References")
LR_dat <- read_excel("literature_review/S2-Result_of_review.xlsx", sheet = "Variables") %>% 
  mutate(Category = factor(Category, levels = c("Environment", "Habitat", "Vegetation", "Others")))

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Summary statistics ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Number of references
LR_studies %>% nrow

# Number of extracted effect sizes
nrow(LR_dat)

# Proportion of studies that indcluded the different categories
LR_dat %>% 
  group_by(Category) %>% 
  summarise(
    `N-Studies` = round(100 * n_distinct(Reference) / nrow(LR_studies), 0))

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Table with summary of literature review ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

LR_dat %>% 
  group_by(Category, Subcategory) %>% 
  summarise(
    `Number of predictor variables` = n_distinct(Predictor_variable),
    `Number of studies` = n_distinct(Reference),
    Importance = mean(Effect != 0) %>% round(2),
    Direction = mean(Effect %>% as.numeric, na.rm = TRUE) %>% round(2)) %>% 
  write.xlsx("results/TABLE_2-summary-review.xlsx")

