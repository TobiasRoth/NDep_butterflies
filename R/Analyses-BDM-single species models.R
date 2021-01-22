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

# Read data
dat <- read_csv("data/raw-data.csv")
dat$ele2 <- dat$ele^2
spec <- read_csv("data/butterflies.csv")
spec$RL1 <- as.integer(!is.na(match(spec$RL, c("NT", "EN"))))
load("data/rec.RData")

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Apply full model to  butterfly species seperately----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

for(s in 1:nrow(spec)) {
  dat$Ind <- rec[,s]
  mod <- glm(
    Ind ~ 
      amt + mtcq + ap + pwq +                  # Climate-gradient
      ts + ps +                                # Climate-Variability
      ele + ele_SD + incli + cd +              # Topography
      fe +                                     # Habitat configuration
      nlut +                                   # Habitat diversity
      ah + agri +                              # Habitat availability
      N + mt + ndep +                          # Land-use intensity
      T + H + L +                              # Microclimate
      PSR,                                     # Resource diversity
    data = dat, family = poisson)
  spec[s, "N_effect"] <- coef(mod)["ndep"]
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Figure that shows differences between species groups ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Number of species
nrow(spec)
table(spec$RL)
sum(spec$UZL)
sum(spec$UZL & spec$RL == "NT")
sum(spec$UZL & spec$RL == "VU")

# Helper funktion to estimate averages and credible intervals
getRes <- function(d) {
  sim <- lm(d ~ 1) %>% sim(10000)
  sim <- sim@coef[,1]
  c(
    estim = mean(sim), 
    lo = quantile(sim, probs = 0.025) %>% as.numeric, 
    up = quantile(sim, probs = 0.975) %>% as.numeric)
}

# Figure for different species groups
rbind(
  getRes(spec$N_effect[spec$RL1 == 1]),
  getRes(spec$N_effect[spec$UZL == 1 & spec$RL1 == 0]),
  getRes(spec$N_effect[spec$RL1 == 0 & spec$UZL == 0])
) %>% 
  as_tibble() %>% 
  mutate(gr = factor(c("Near threatened and\nvulnerable species", "Target species\nfor agriculture", "Remaining species"), 
                     levels = c("Near threatened and\nvulnerable species", "Target species\nfor agriculture", "Remaining species"))) %>% 
  ggplot(aes(x = gr, y = estim, ymin = lo, ymax = up)) +
  geom_point(cex = 1.5) +
  geom_errorbar(width = 0.1) +
  geom_abline(slope = 0, intercept = 0, lty = 2) +
  ylim(-3, 1) +
  theme_clean() + 
  theme(axis.line = element_blank()) +
  labs(
    y = "Effect size of N deposition",
    x = ""
  )
ggsave("results/FIG_4-Ndep_effects_species_abundance.pdf", width = 7, height = 3.5)



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Save species list as Appendix A4 ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
openxlsx::write.xlsx(
  spec %>% transmute(
    Genus = Gattung,
    Species = Art,
    RL = RL,
    UZL = UZL,
    Ndep_Effect = N_effect
  ), 
  file = "results/TABLE_A4-NdepEff_species.xlsx")


