rm(list=ls(all=TRUE))

# Load libraries
library(tidyverse)

# Connection to data base (not available from Github!)
dat <- read_csv("data/raw-data.csv")

# Function to calculate correlation coefficient
panel.cor <- function(x, y, digits = 2, prefix = "", cex.cor, ...)
{
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  r <- abs(cor(x, y))
  txt <- format(c(r, 0.123456789), digits = digits)[1]
  txt <- paste0(prefix, txt)
  if(missing(cex.cor)) cex.cor <- 0.8/strwidth(txt)
  text(0.5, 0.5, txt, cex = cex.cor * r)
}

# Make correlation matrix
png("results/S3-corellation_between_variables.png", width = 2000, height = 2000)
pairs(dat[, -1], upper.panel = panel.cor)
dev.off()
