rm(list=ls(all=TRUE))

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Settings and load data----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Libraries
library(tidyverse)
library(ggthemes)
library(arm)
library(broom)
library(openxlsx)
library(readxl)

# Read data
dat <- read_csv("data/raw-data.csv")
dat$ele2 <- dat$ele^2

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Describe set of linear models ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# (1) Full model
full <- lm(
  BSR ~ 
    amt + mtcq + ap + pwq +                  # Climate-gradient
    ts + ps +                                # Climate-Variability
    ele + ele_SD + incli + cd +              # Topography
    fe +                                     # Habitat configuration
    nlut +                                   # Habitat diversity
    ah + agri +                              # Habitat availability
    N + mt + ndep +                          # Land-use intensity
    T + H + L +                              # Microclimate
    PSR,                                     # Resource diversity
  data = dat)
# plot(full)

# (2) Full model without microclimate variables
full_without_micro <- lm(
  BSR ~ 
    amt + mtcq + ap + pwq +                  # Climate-gradient
    ts + ps +                                # Climate-Variability
    ele + ele_SD + incli + cd +              # Topography
    fe +                                     # Habitat configuration
    nlut +                                   # Habitat diversity
    ah + agri +                              # Habitat availability
    N + mt + ndep +                          # Land-use intensity
    PSR,                                     # Resource diversity
  data = dat)

# (3) Topo-climate model
topoclimate <- lm(
  BSR ~ 
    amt + mtcq + ap + pwq +                  # Climate-gradient
    ts + ps +                                # Climate-Variability
    ele + ele_SD + incli + cd +              # Topography
    ndep,
  data = dat) 

# (4) Climate model
climate <- lm(
  BSR ~ 
    amt + ap +                               # Climate-gradient
    ndep,
  data = dat) 


# (5) Land-use model
landuse <- lm(
  BSR ~ 
    ele + I(ele^2) +                         # Proxy for temperature
    fe +                                     # Habitat configuration
    nlut +                                   # Habitat diversity
    ah + agri +                              # Habitat availability
    N + mt + ndep,                           # Land-use intensity
  data = dat)

# (6) Minimalistic model 
minimalistic <- lm(BSR ~ ele + I(ele^2) + ndep, data = dat)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Apply models and plot N-deposition results from each model----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Number of simulations (for sim())
nsim <- 1000 

# Function to extract coefficients fro ndep from posterior samples
getndep <- function(x) coef(x)[, "ndep"]

# Function to get posterior predictions for ndep for a given model
getpost <- function(mod) {
  post <- sim(mod, nsim) %>% getndep
  list(
    mean = mean(post),
    low = quantile(post, 0.025),
    up = quantile(post, 0.975))
}

# Make figure with results of all models
modlist <- list(
  full, 
  full_without_micro,
  topoclimate, 
  climate, 
  landuse, 
  minimalistic)
modname <- c(
  "Full model", 
  "Full model without\nmicroclimate variables",
  "Topo-climate model", 
  "Climate model", 
  "Land-use model", 
  "Minimalistic model")

# Make plot
map_df(modlist, getpost) %>% 
  add_column(modname) %>% 
  ggplot(aes(x = modname %>% factor(levels = modname %>% rev), y = mean)) +
  geom_abline(slope = 0, intercept = 0, lty = 2) +
  geom_abline(slope = 0, intercept = seq(-0.9, -0.3, 0.3), lty = 3) +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = up), width = 0.2) + 
  labs(y = "Effect size of nitrogen deposition on butterfly species richness",
       x = "") +
  ylim(NA, 0) +
  coord_flip() +
  theme_clean() + 
  theme(axis.line = element_blank())
ggsave("results/FIG_1-linear_model_results.pdf", width = 7, height = 3.5)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Table of results from full model ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

full %>% 
  tidy %>% 
  filter(term != "(Intercept)") %>% 
  left_join(read_excel("data/TABLE_1-variable_description.xlsx"), by = c("term" = "Acronym")) %>% 
  transmute(
    `Predictor variable` = term,
    Description = Description,
    Estimate = round(estimate, 3),
    SE = round(std.error, 3),
    P = round(p.value, 3))  %>% 
  write.xlsx("results/TABLE_3-results-full-model.xlsx")
