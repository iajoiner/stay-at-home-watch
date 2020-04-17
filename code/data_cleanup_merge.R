
# declare dependencies
if (!exists("setup_sourced")) source(here::here("code", "setup.R"))

#---------------------------------------------------------------------

# load data
maps_data <- read_csv("data/final_data.csv")
glimpse(maps_data)

# clean out the 'none' post-fixes in the juristiction field
maps <- maps_data %>%
  mutate(c = str_replace(jurisdiction, "-None-None", "")) %>%
  mutate(country = str_replace(c, "-None", ""))

maps <- maps[, -c(1,2)]
maps <- maps[,-8]

google_canada <- maps %>%
  filter(str_detect(maps$country, "Canada")) %>%
  mutate(Province = str_replace(country, ",Canada", "")) %>%
  mutate(Province = as.factor(Province))


google_canada <- google_canada[,-8]

#---------------------------------------------------------------------

library(ggExtra) 

g <- ggplot(data = google_canada, 
       aes(x = Province, y = parks)) +
  geom_point(aes(col=parks, size=workplace)) + 
  geom_smooth(method="loess", se=F) + 
  labs(subtitle="Stay-at-Home-Watch", 
       y="parks", 
       x="Canadian Provinces", 
       title="Park mobility scatterplot for Canada", 
       caption = "Source: Google Maps") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggsave("scatterplot_canada.pdf")

ggMarginal(g, type = "histogram", fill="transparent")

#---------------------------------------------------------------------
# load confirmed cases
confirmed <- fread(here::here("csse_covid_19_data", "csse_covid_19_time_series", "time_series_covid19_confirmed_global.csv")) 
death <- fread(here::here("csse_covid_19_data", "csse_covid_19_time_series", "time_series_covid19_deaths_global.csv"))
recovered <- fread(here::here("csse_covid_19_data", "csse_covid_19_time_series", "time_series_covid19_recovered_global.csv"))

#-----------------------------------------------------------

# make a dataframe for all of Canada
drop_columns <- c("Country/Region", "Lat", "Long")

ccc <- confirmed %>%
  filter(`Country/Region` == "Canada") %>%
  select(-one_of(drop_columns)) %>%
  pivot_longer(-`Province/State`, names_to = "date", values_to = "confirmed_counts") %>%
  mutate(date = mdy(date)) %>%
  rename(Province = `Province/State`)


dcc <- death %>%
  filter(`Country/Region` == "Canada") %>%
  select(-one_of(drop_columns)) %>%
  pivot_longer(-`Province/State`, names_to = "date", values_to = "death_counts") %>%
  mutate(date = mdy(date)) %>%
  rename(Province = `Province/State`)


rcc <- recovered %>%
  filter(`Country/Region` == "Canada") %>%
  select(-one_of(drop_columns)) %>%
  pivot_longer(-`Province/State`, names_to = "date", values_to = "recovered_counts") %>%
  mutate(date = mdy(date)) %>%
  rename(Province = `Province/State`)


combinedc <- cbind(ccc, dcc, rcc, by = "date") 

combinedc_cleanup <- combinedc[,c(1:3, 6, 9)]

# make data to visualize
JHU <- combinedc_cleanup %>%
  filter(!Province == "Diamond Princess") %>%
  filter(!Province == "Grand Princess") %>%
  filter(!Province == "Recovered") %>%
  mutate(death_counts = case_when(death_counts == "1" ~ "Yes",
                                  TRUE ~ "No")) %>%
  mutate(week_in_2020 = week(date)) %>%
  mutate(Province = as.factor(Province))

#-----------------------------------------------------------

# JHU data
head(JHU)

# Google maps data
head(google_canada)

merged_data <- merge(google_canada, JHU, by = "Province")

#-----------------------------------------------------------

# download shp files from statscan
## https://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/bound-limit-eng.cfm
## e.g. for shp files for census tracts, download: https://www12.statcan.gc.ca/census-recensement/alternative_alternatif.cfm?l=eng&dispext=zip&teng=lct_000a16a_e.zip&k=%20%20%20%20%207190&loc=http://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/files-fichiers/2016/lct_000a16a_e.zip

library(maps)
library(mapdata)

map("worldHires","Canada",
xlim=c(-141,-53), #xlim is lattitude
ylim=c(40,85), #yilm is longitude
col="gray90",
fill=TRUE, add = TRUE) # add = TRUE allows additional layers


library(mapproj)
map("worldHires","Canada",
xlim=c(-141,-53),
ylim=c(40,85),
col="gray90",
fill=TRUE,
projection="conic",
param=35, add = TRUE)

# read in .shp files
canada_map_poly <- sf::st_read("/Users/noushinnabavi/covid_19_analysis/polygons/lct_000a16a_e/lct_000a16a_e.shp") %>%
  rename(Province = PRNAME) %>%
  mutate(Province = as.factor(Province))


merged_data[merged_data$Province == canada_map_poly$Province]

merge(merged_data, canada_map_poly, by = Province)
#-----------------------------------------------------------


