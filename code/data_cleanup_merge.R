
# declare dependencies
if (!exists("setup_sourced")) source(here::here("scripts", "setup.R"))

#---------------------------------------------------------------------

# load data
maps_data <- read_csv("data/final_data.csv")
glimpse(maps_data)

# clean out the 'none' post-fixes in the juristiction field
maps <- maps_data %>%
  mutate(c = str_replace(jurisdiction, "-None-None", "")) %>%
  mutate(country = str_replace(c, "-None", ""))

maps <- maps[, -c(1,2)]
maps <- maps[,-6]

canada <- maps %>%
  filter(str_detect(maps$country, "CA")) 
 
library(ggExtra) 
g <- ggplot(data = canada, 
       aes(x = country, y = parks)) +
  geom_point(aes(col=parks, size=workplace)) + 
  geom_smooth(method="loess", se=F) + 
  labs(subtitle="Stay-at-Home-Watch", 
       y="parks", 
       x="Canadian Provinces", 
       title="Park mobility scatterplot", 
       caption = "Source: Google Maps")

ggMarginal(g, type = "histogram", fill="transparent")




