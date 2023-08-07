library(dplyr) ### Data manipulation
# library(tidyverse) #dataframe manipulation and to remove NAs from columns

### Import data
FINAL_GOOSE_DATA <- f <- read.csv("/scratch/mcallen/goose/FINAL_GOOSE_DATA.csv") %>%
  rename(dist = DISTANCE,
         year = ENCOUNTER_YEAR,
         species = B_SPECIES_NAME,
         lat = B_LAT_DECIMAL_DEGREES
  ) %>%
  mutate(zy = wiqid::standardize(dist),
         zx = wiqid::standardize(year),
         zlat = wiqid::standardize(lat))

# reduced data set for testing
ind <- sample(x = 1:nrow(f), size = 500, replace = F)
fr <- f[ind,]

# format data for JAGS
goose_jags_data <- list(
  y = f$dist,
  x = f$year,
  s = as.numeric(as.factor(f$species)),
  Nsubj = length(unique(f$species)),
  lat=f$lat,
  zy = f$zy,
  zx = f$zx,
  zlat = f$zlat,
  Ntotal = length(f$dist)
)

inits <- list(zbeta0 <- structure(c(-0.663321040671236, 0.954560439341569, 0.519080213754324, 
                                    0.458799688305308, -0.49806997756865, -0.332464791364721), .Dim = 6L),
              zbeta1 <- structure(c(-0.129711132179005, 0.166300843268756, -0.0836665075211784, 
                                    0.229873835923267, -0.0690458264897419, 0.0582558751114997), .Dim = 6L),
              zbeta2 <- structure(c(1.54571001487761, -0.180515413196703, 1.33293783894519, 
                          0.10686206227311, 0.443833665251355, 0.432483503929939), .Dim = 6L),
              zbeta3 <- structure(c(-0.644887267070986, 0.256280806830324, -0.0634262191708101, 
                                    -0.414363252389715, 0.00508398197826996, 0.249318311819725), .Dim = 6L),
              zsigma <- structure(c(0.126167105613967, 0.632625522586079, 0.172651942449704, 
                                    0.562349705507502, 0.37765582368873, 0.379580063257011), .Dim = 6L),
              zbeta0mu <- 0.792, zbeta1mu <- 0.0294, zbeta2mu <- 0.194, zbeta3mu <- 0.0174)

modfile <- "/scratch/mcallen/goose/goose_model_year_lat_interaction_hypers.txt"

# Run the model with separate SDs by species
jags_mod <- jagsUI::jags(
  data = goose_jags_data, # goose_jags_data,
  model.file = modfile,
  n.iter = 50000,
  n.burnin = 30000,
  parameters.to.save = c(
    "zbeta0",
    "zbeta1",
    "zbeta2",
    "zbeta3",
    "zbeta0mu",
    "zbeta1mu",    
    "zbeta2mu",    
    "zbeta3mu",
    "zsigma",
    "nu"
  ),
  n.chains = 3,
  parallel = T,
  n.thin = 10
)

# save the model output as an RDS file (for easy loading later)
saveRDS(jags_mod,
        "/scratch/mcallen/goose/goose_mod_tdist_hierarchical_int_hypers.rds")