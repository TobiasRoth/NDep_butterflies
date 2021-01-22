rm(list=ls(all=TRUE))

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Settings ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Libraries
library(tidyverse)
library(kableExtra)
library(sf)
library(raster)
library(BDM)

# Connection to data base (not available from Github!)
db <- src_sqlite(path = "db//DB_BDM_2019_05_31.db", create = FALSE)

# Start and end year of study
startyr <- 2005
endyr <- 2009

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Number of sites for methods ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Number of sites on regular grid
tbl(db, "STICHPROBE_Z7") %>% 
  filter(BDM_Grid == "ja") %>% 
  filter(BDM_Verdichtung == "nein") %>% 
  as_tibble %>% nrow()
  
# Number of sites excluded because too dangerous to survey
tbl(db, "STICHPROBE_Z7") %>% 
  filter(BDM_Grid == "ja") %>% 
  filter(BDM_Verdichtung == "nein") %>% 
  filter(BDM_Ausschlussjahr <= 2009 & !is.na(BDM_Ausschlussjahr)) %>% 
  as_tibble %>% nrow()

# Number of sites excluded because lakes
tbl(db, "STICHPROBE_Z7") %>% 
  filter(BDM_Grid == "ja") %>% 
  filter(BDM_Verdichtung == "nein") %>% 
  pull(BDM_Ausschlussgrund) %>% table
  
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Selection of sites ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ausw <- 
  tbl(db, "KD_Z7") %>%  
  left_join(tbl(db, "Raumdaten_Z7")) %>% 
  filter(!is.na(yearPl) & !is.na(yearBu)) %>%
  filter(yearP >= startyr & yearPl <= endyr) %>% 
  filter(Aufnahmetyp == "Normalaufnahme_Z7" | Aufnahmetyp == "BDM_LANAG_Normalaufnahme_Z7") %>% 
  filter(Verdichtung_BDM == "nein") %>% 
  transmute(
    aID_KD = aID_KD, 
    aID_STAO = aID_STAO,
    yearP = yearP,
    year_Pl = yearPl,
    year_Bu = yearBu
  ) %>% 
  as_tibble() 

# Add shapes of 1km2
ausw <- 
  ausw %>% 
  st_sf(geometry = st_as_sfc(makesq(ausw$aID_STAO, projection = 'CH-old')))

# Prepare tibble for site covariates (dat) 
dat <-
  tibble(
    siteID = 1:nrow(ausw)
  )

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Climate-Gradient ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Download worldclim data
d <- getData("worldclim", var = "bio", res = 0.5, lat = 46.9, lon = 8.6, path = "db/") %>% 
  crop(extent(ausw %>% st_transform(crs = 4326))) %>% 
  extract(y = ausw, fun = mean, na.rm = TRUE) %>% 
  as_tibble()

# Annual Mean Temperature
dat <-
  dat %>% 
  add_column("amt" = (d$bio1_16 - 50) / 20)

# Mean Temperature of Coldest Quarter
dat <-
  dat %>% 
  add_column("mtcq" = (d$bio11_16 - 0) / 20)

# Annual Precipitation
dat <-
  dat %>% 
  add_column("ap" = (d$bio12_16 - 1000) / 200)

# Precipitation of Warmest Quarter
dat <-
  dat %>% 
  add_column("pwq" = (d$bio18_16 - 400) / 50)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Climate-Variability ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Temperature Seasonality (standard deviation *100)
d$bio4_16 <- d$bio4_16 / 1000
dat <-
  dat %>% 
  add_column("ts" = (d$bio4_16 - 6) / 0.5)

# Precipitation Seasonality (Coefficient of Variation)
dat <-
  dat %>% 
  add_column("ps" = (d$bio15_16 - 20) / 5)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Topography ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Load geo-data
d <- read_delim("~/Documents/Dropbox/Datengrundlagen/Gelaendedaten/Gelaendedaten.CSV.zip", delim = ";")

# Elevation
tmp <-  
  d %>% 
  transmute(x = KX, y = KY, z = HOEHE) %>% 
  rasterFromXYZ(crs = CRS("+init=epsg:21781")) %>% 
  extract(y = ausw, fun = median, na.rm = TRUE)
dat <- 
  dat %>% 
  add_column("ele" = (tmp[,1] - 1000) / 200)

# SD of elevation
tmp <-  
  d %>% 
  transmute(x = KX, y = KY, z = HOEHE) %>% 
  rasterFromXYZ(crs = CRS("+init=epsg:21781")) %>% 
  extract(y = ausw, fun = sd, na.rm = TRUE)
dat <-
  dat %>% 
  add_column("ele_SD" = (tmp[,1] - 100) / 50)

# Inclination
tmp <-  
  d %>% 
  transmute(x = KX, y = KY, z = NEIG) %>% 
  rasterFromXYZ(crs = CRS("+init=epsg:21781")) %>% 
  extract(y = ausw, fun = mean, na.rm = TRUE)
dat <-
  dat %>% 
  add_column("incli" = (tmp[,1] - 10) / 5)

# Number of the eight cardinal directions
d$EXPOST[d$EXPOST == 0] <- NA
d$EXPOST[d$EXPOST == 9] <- NA
tmp <-  
  d %>% 
  transmute(x = KX, y = KY, z = EXPOST) %>% 
  rasterFromXYZ(crs = CRS("+init=epsg:21781")) %>% 
  extract(y = ausw, fun = function(x, ...) {n_distinct(x, na.rm = TRUE)}, na.rm = TRUE)
dat <-
  dat %>% 
  add_column("cd" = (tmp[,1] - 4) / 2)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Habitat configuration ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Load geo-data
d <- st_read("~/Documents/Dropbox/Datengrundlagen/Landnutzung/Gesamte_CH/Landnutzung_v2.shp", crs = 2056) %>% 
  filter(Landnutz == "Wald") %>% 
  st_cast("MULTILINESTRING")

# Length of forest edges
tt <- 
  map_dbl(
    1:nrow(ausw),
    function(i) {
      tmp <- st_intersection(d, ausw[i,] %>% st_transform(crs = 2056)) 
      ifelse(nrow(tmp) > 0, st_length(tmp), 0)
    }
  )
dat <-
  dat %>% 
  add_column("fe" = (as.vector(tt) - 5000) / 1000)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Habitat diversity ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Load geo-data
d <- read_delim("~/Documents/Dropbox/Datengrundlagen/Arealstatistik/NOAS04-72 Kategorien/AREA_NOAS04_72_130918.csv.zip", delim = ";")

# Number of land-use types
tmp <-  
  d %>% 
  transmute(x = X, y = Y, z = AS09_27) %>% 
  rasterFromXYZ(crs = CRS("+init=epsg:21781")) %>% 
  extract(y = ausw, fun = function(x, ...) n_distinct(x, na.rm = TRUE))
dat <-
  dat %>% 
  add_column("nlut" = (tmp[,1] - 10) / 3)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Habitat availability ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Percent of agricultural land
tmp <-  
  d %>% 
  transmute(x = X, y = Y, z = AS09_4) %>% 
  rasterFromXYZ(crs = CRS("+init=epsg:21781")) %>% 
  extract(y = ausw, fun = function(x, ...) 100 * mean(x == 2, na.rm = TRUE), na.rm = TRUE)
dat <-
  dat %>% 
  add_column("agri" = (tmp[,1] - 50) / 10)

# Available habitat (total area minus sealed areas and open water)
tmp <-  
  d %>% 
  transmute(x = X, y = Y, z = AS09_27) %>% 
  rasterFromXYZ(crs = CRS("+init=epsg:21781")) %>% 
  extract(y = ausw, fun = function(x, ...) 100 * mean(x > 6 & x != 23 & x != 27, na.rm = TRUE), na.rm = TRUE)
dat <-
  dat %>% 
  add_column("ah" = (tmp[,1] - 80) / 10)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Land-use intensity ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Mean N value
tt <- 
  ausw %>% 
  dplyr::select(aID_KD) %>% 
  st_set_geometry(NULL) %>% 
  left_join(
    tbl(db, "PL") %>% filter(Z7 == 1) %>% 
      left_join(tbl(db, "Traits_Pl")) %>% 
      group_by(aID_KD) %>% 
      summarise(xx = mean(N, na.rm = TRUE)),
    copy = TRUE) %>% 
  pull(xx)
dat <-
  dat %>% 
  add_column("N" = (tt - 3) / 0.1)

# Mean MV value
tt <- 
  ausw %>% 
  dplyr::select(aID_KD) %>% 
  st_set_geometry(NULL) %>% 
  left_join(
    tbl(db, "PL") %>% filter(Z7 == 1) %>% 
      left_join(tbl(db, "Traits_Pl")) %>% 
      group_by(aID_KD) %>% 
      summarise(xx = mean(MV, na.rm = TRUE)),
    copy = TRUE) %>% 
  pull(xx)
dat <-
  dat %>% 
  add_column("mt" = (tt - 2.5) / 0.1)

# Nitrogen deposition 
tmp <- 
  ausw %>% 
  st_set_geometry(NULL) %>% 
  transmute(aID_STAO = aID_STAO) %>% 
  left_join(
    read_delim("db/1093_haz7_130513.csv", delim = ";") %>% 
      transmute(
        aID_STAO = coordID,
        Ndep = (DN_TRAN - 10) / 10)
  )
dat <- 
  dat %>% 
  add_column(ndep = tmp$Ndep)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Microclimate in vegetation ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Mean T value
tt <- 
  ausw %>% 
  dplyr::select(aID_KD) %>% 
  st_set_geometry(NULL) %>% 
  left_join(
    tbl(db, "PL") %>% filter(Z7 == 1) %>% 
      left_join(tbl(db, "Traits_Pl")) %>% 
      group_by(aID_KD) %>% 
      summarise(xx = mean(T, na.rm = TRUE)),
    copy = TRUE) %>% 
  pull(xx)
dat <-
  dat %>% 
  add_column("T" = (tt - 3.5) / 0.1)

# Mean F value (humidity)
tt <- 
  ausw %>% 
  dplyr::select(aID_KD) %>% 
  st_set_geometry(NULL) %>% 
  left_join(
    tbl(db, "PL") %>% filter(Z7 == 1) %>% 
      left_join(tbl(db, "Traits_Pl")) %>% 
      group_by(aID_KD) %>% 
      summarise(xx = mean(F, na.rm = TRUE)),
    copy = TRUE) %>% 
  pull(xx)
dat <-
  dat %>% 
  add_column("H" = (tt - 3) / 0.1)

# Mean L value
tt <- 
  ausw %>% 
  dplyr::select(aID_KD) %>% 
  st_set_geometry(NULL) %>% 
  left_join(
    tbl(db, "PL") %>% filter(Z7 == 1) %>% 
      left_join(tbl(db, "Traits_Pl")) %>% 
      group_by(aID_KD) %>% 
      summarise(xx = mean(L, na.rm = TRUE)),
    copy = TRUE) %>% 
  pull(xx)
dat <-
  dat %>% 
  add_column("L" = (tt - 3.5) / 0.1)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Resource diversity ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Species richness of plants
tt <- 
  ausw %>% 
  dplyr::select(aID_KD) %>% 
  st_set_geometry(NULL) %>% 
  left_join(
    tbl(db, "PL") %>% filter(Z7 == 1) %>% 
      group_by(aID_KD) %>% 
      summarise(xx = n()),
    copy = TRUE) %>% 
  pull(xx)
dat <-
  dat %>% 
  add_column("PSR" = sqrt(tt) -15)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Dependent variable: butterfly species richness ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Species richness of butterflies
tt <- 
  ausw %>% 
  dplyr::select(aID_KD) %>% 
  st_set_geometry(NULL) %>% 
  left_join(
    tbl(db, "TF") %>% 
      group_by(aID_KD) %>% 
      summarise(xx = n()),
    copy = TRUE) %>% 
  pull(xx)
dat <-
  dat %>% 
  add_column("BSR" = sqrt(tt) -5)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Prepare dat for all butterfly species ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Select all butterfly records from analysed surveys
bu <- tbl(db, "TF") %>% 
  dplyr::filter(!is.na(aID_SP)) %>% 
  dplyr::select(aID_KD, aID_SP, Ind) %>% 
  as_tibble() %>% 
  filter(!is.na(match(aID_KD, ausw$aID_KD)))

# Prepare list of species 
spec <- tbl(db, "Arten") %>% 
  dplyr::filter(Z7Z9 == 1 & TF == 1) %>% 
  dplyr::select(aID_SP, Gattung, Art, RL, UZL) %>% 
  as_tibble() %>% 
  left_join(
    bu %>% 
      group_by(aID_SP) %>% 
      dplyr::summarise(
        records = n())
  ) %>% 
  replace_na(list(records = 0)) 
sum(spec$records > 0)  

# Prepare sites x species matrix with number of records
spec <- spec %>% dplyr::filter(records >= 20) 
rec <- matrix(NA, nrow = nrow(ausw), ncol = nrow(spec))
for(s in 1:nrow(spec)) {
  rec[, s] <- ausw %>% 
    st_set_geometry(NULL) %>% 
    dplyr::select(aID_KD) %>% 
    left_join(
      bu %>% 
        dplyr::filter(aID_SP == spec$aID_SP[s]) 
    ) %>% 
    replace_na(list(Ind = 0)) %>% 
    pull(Ind)
}
  
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Save data ----
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Save data
write_csv(dat, path = "data/raw-data.csv")
write_csv(spec, path = "data/butterflies.csv")
save(rec, file = "data/rec.RData")


