rm(list=ls(all=TRUE))

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Settings and load data----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Libraries
library(tidyverse)
library(lavaan)
library(DiagrammeR)
library(DiagrammeRsvg)
library(rsvg)
library(readxl)

# Read data
dat <- read_csv("data/raw-data.csv")
dat$ele2 <- dat$ele^2
dat$L <- resid(lm(L ~ ele + ele2, data = dat))
dat$T <- resid(lm(T ~ ele + ele2, data = dat))
dat$H <- resid(lm(H ~ ele + ele2, data = dat))

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Plot of generic model ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Definition of Nodes 
setting <- read_excel("div/setting_generic_model.xlsx", sheet = "nodes_generic")
no <- create_node_df(
  n = length(setting$label),
  shape = setting$shape,
  label = setting$label,
  x = setting$x,
  y = setting$y,
  height = setting$height,
  width = setting$width,
  color = "black",
  fontcolor = "black",
  fillcolor = setting$fillcolor
)

# Definition of edges
setting <- read_excel("div/setting_generic_model.xlsx", sheet = "edges_generic")
ed <- create_edge_df(
  from = setting$from, 
  to = setting$to,
  fontsize = setting$fontsize,
  color = setting$color,
  penwidth = setting$penwidth
)

# Make graph
create_graph(
  nodes_df = no,
  edges_df = ed) %>%
  export_graph(file_name = "results/S4-generic-model.pdf", file_type = "pdf")

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Apply main model ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# SEM Model definition
sem <-'
BSR ~ climate + LU_intens + habitat + PSR + microclim + ele + ele2
PSR ~ climate + adep + LU_intens + habitat + microclim  + ele + ele2
microclim ~ climate + adep + LU_intens

climate =~  amt + mtcq + ap + pwq
adep =~ ndep
LU_intens =~ N + mt + incli 
habitat =~ ah
microclim =~ T + H  + L
'

# Definition of Nodes 
setting <- read_excel("div/setting_generic_model.xlsx", sheet = "nodes_main")
no <- create_node_df(
  n = length(setting$label),
  shape = setting$shape,
  label = setting$label,
  x = setting$x,
  y = setting$y,
  height = setting$height,
  width = setting$width,
  color = "black",
  fontcolor = "black",
  fillcolor = setting$fillcolor,
  fontsize = setting$fontsize
)

# Run SEM to all data
d <- dat
res <- sem(sem, data = d)
partable <- res@ParTable %>% 
  as_tibble() %>% 
  filter(!is.na(match(lhs, setting$variable)) & !is.na(match(rhs, setting$variable))) %>% 
  filter(op != "~~")
ed <- create_edge_df(
  from = match(partable$rhs, setting$variable), 
  to = match(partable$lhs, setting$variable),
  fontsize = 6,
  color = ifelse(partable$est >= 0, "grey60", "orange"),
  penwidth = 10 * abs(partable$est)
)
ed$penwidth[ed$penwidth > 10] <- 10
ed$penwidth[ed$penwidth < -10] <- -10
create_graph(
  nodes_df = no,
  edges_df = ed) %>%
  export_graph(file_name = "results/FIG_2a-SEM-results-all-data.pdf", file_type = "pdf")

# Run SEM to data of sites <1600m
d <- dat %>% filter(ele < ((1500 - 500) / 200))
res <- sem(sem, data = d)
partable <- res@ParTable %>% 
  as_tibble() %>% 
  filter(!is.na(match(lhs, setting$variable)) & !is.na(match(rhs, setting$variable))) %>% 
  filter(op != "~~")
ed <- create_edge_df(
  from = match(partable$rhs, setting$variable), 
  to = match(partable$lhs, setting$variable),
  fontsize = 6,
  color = ifelse(partable$est >= 0, "grey60", "orange"),
  penwidth = 10 * abs(partable$est)
)
ed$penwidth[ed$penwidth > 10] <- 10
ed$penwidth[ed$penwidth < -10] <- -10
create_graph(
  nodes_df = no,
  edges_df = ed) %>%
  export_graph(file_name = "results/FIG_2b-SEM-results-below_1600m.pdf", file_type = "pdf")

# Run SEM to data of sites <1600m
d <- dat %>% filter(ele >= ((1500 - 500) / 200))
res <- sem(sem, data = d)
partable <- res@ParTable %>% 
  as_tibble() %>% 
  filter(!is.na(match(lhs, setting$variable)) & !is.na(match(rhs, setting$variable))) %>% 
  filter(op != "~~")
ed <- create_edge_df(
  from = match(partable$rhs, setting$variable), 
  to = match(partable$lhs, setting$variable),
  fontsize = 6,
  color = ifelse(partable$est >= 0, "grey60", "orange"),
  penwidth = 10 * abs(partable$est)
)
ed$penwidth[ed$penwidth > 10] <- 10
ed$penwidth[ed$penwidth < -10] <- -10
create_graph(
  nodes_df = no,
  edges_df = ed) %>%
  export_graph(file_name = "results/FIG_2c-SEM-results-above_1600m.pdf", file_type = "pdf")

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Apply model with direct N deposition effect on butterfly species richness ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Model definition
sem <-'
BSR ~ climate + adep + LU_intens + habitat + PSR + microclim + ele + ele2
PSR ~ climate + adep + LU_intens + habitat + microclim  + ele + ele2
microclim ~ climate + adep + LU_intens

climate =~  amt + mtcq + ap + pwq
adep =~ ndep
LU_intens =~ N + mt + incli 
habitat =~ ah
microclim =~ T + H  + L
'
# Run SEM to all data
d <- dat
res <- sem(sem, data = d)
partable <- res@ParTable %>% 
  as_tibble() %>% 
  filter(!is.na(match(lhs, setting$variable)) & !is.na(match(rhs, setting$variable))) %>% 
  filter(op != "~~")
ed <- create_edge_df(
  from = match(partable$rhs, setting$variable), 
  to = match(partable$lhs, setting$variable),
  fontsize = 6,
  color = ifelse(partable$est >= 0, "grey60", "orange"),
  penwidth = 10 * abs(partable$est)
)
ed$penwidth[ed$penwidth > 10] <- 10
ed$penwidth[ed$penwidth < -10] <- -10
create_graph(
  nodes_df = no,
  edges_df = ed) %>%
  export_graph(file_name = "results/S6-SEM-with_direct_N_effect.pdf", file_type = "pdf")

