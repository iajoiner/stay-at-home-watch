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

fwrite(google_canada, here::here("map_app", "google_canada.csv"), sep = ",")
#-----------------------------------------------------------

# Map covid cases on Canada map
# If the .shp files (provinces) aren't already downloaded on your system, this command downloads them
library(leaflet)
if (!file.exists("./polygons/ne_50m_admin_1_states_provinces_lakes/ne_50m_admin_1_states_provinces_lakes.dbf")){
  download.file(file.path('http://www.naturalearthdata.com/http/',
                          'www.naturalearthdata.com/download/50m/cultural',
                          'ne_50m_admin_1_states_provinces_lakes.zip'),
                f <- tempfile())
  unzip(f, exdir = "./polygons/ne_50m_admin_1_states_provinces_lakes")
  rm(f)
}

# Read the .shp files
provinces <- rgdal::readOGR("./polygons/ne_50m_admin_1_states_provinces_lakes", 'ne_50m_admin_1_states_provinces_lakes', encoding='UTF-8')

# Google maps data
head(google_canada)

# combine to map
provinces3  <- sp::merge(
  provinces,
  google_canada,
  by.x = "name",
  by.y = "Province",
  sort = FALSE,
  incomparables = NULL,
  duplicateGeoms = TRUE
)


clear <- "#F2EFE9"
lineColor <- "#000000"
hoverColor <- "red"
lineWeight <- 0.5

pal <- leaflet::colorNumeric(palette = 'Purples', c(max(google_canada$parks), min(google_canada$parks)), reverse = FALSE)
pal2 <- leaflet::colorNumeric(palette = 'Blues', c(max(google_canada$workplace), min(google_canada$workplace)), reverse = FALSE)
pal3 <- leaflet::colorNumeric(palette = 'Reds', c(max(google_canada$grocery_pharmacy), min(google_canada$grocery_pharmacy)), reverse = FALSE)


provinces3 %>%
  leaflet() %>%
  leaflet(options = leafletOptions(zoomControl = FALSE,
                                   minZoom = 3, maxZoom = 3,
                                   dragging = FALSE)) %>%
  addTiles() %>%
  setView(-110.09, 62.7,  zoom = 3) %>%
  addPolygons(data = subset(provinces3, name %in% c("British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Québec", "New Brunswick", "Prince Edward Island", "Nova Scotia", "Newfoundland and Labrador", "Yukon", "Northwest Territories", "Nunavut")),
              fillColor = ~ pal(parks),
              fillOpacity = 0.5,
              stroke = TRUE,
              weight = lineWeight,
              color = lineColor,
              highlightOptions = highlightOptions(fillOpacity = 1, bringToFront = TRUE, sendToBack = TRUE),
              label=~stringr::str_c(
                name,' ',
                formatC(parks)),
              labelOptions= labelOptions(direction = 'auto'),
              group = "parks") %>%
  
  addPolygons(data = subset(provinces3, name %in% c("British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Québec", "New Brunswick", "Prince Edward Island", "Nova Scotia", "Newfoundland and Labrador", "Yukon", "Northwest Territories", "Nunavut")),
              fillColor = ~ pal2(workplace),
              fillOpacity = 0.5,
              stroke = TRUE,
              weight = lineWeight,
              color = lineColor,
              highlightOptions = highlightOptions(fillOpacity = 1, bringToFront = TRUE, sendToBack = TRUE),
              label=~stringr::str_c(
                name,' ',
                formatC(workplace)),
              labelOptions= labelOptions(direction = 'auto'),
              group = "workplace") %>%
  
  addPolygons(data = subset(provinces3, name %in% c("British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Québec", "New Brunswick", "Prince Edward Island", "Nova Scotia", "Newfoundland and Labrador", "Yukon", "Northwest Territories", "Nunavut")),
              fillColor = ~ pal3(grocery_pharmacy),
              fillOpacity = 0.5,
              stroke = TRUE,
              weight = lineWeight,
              color = lineColor,
              highlightOptions = highlightOptions(fillOpacity = 1, bringToFront = TRUE, sendToBack = TRUE),
              label = ~ stringr::str_c(
                name, ' ',
                formatC(grocery_pharmacy)),
              labelOptions= labelOptions(direction = 'auto'),
              group = "grocery_pharmacy") %>%
  
  addLayersControl(overlayGroups = c("parks", "workplace", "grocery_pharmacy"),
                   options = layersControlOptions(collapsed = FALSE),
                   position = 'topright') %>%
  addLegend(pal = pal,
            values = google_canada$parks,
            position = "bottomleft",
            title = "Mobilities in Canada",
            labFormat = labelFormat(suffix = "", transform = function(x) sort(x, decreasing = FALSE)))

