options(shiny.sanitize.errors = TRUE)
# -------------------------------------------------------------------------

library(shiny)

# Define server logic for random distribution app ----

server <- function(input, output) {
  
  # Generate a plot of the data ----
  # Also uses the inputs to build the plot label. Note that the
  # dependencies on the inputs and the data reactive expression are
  # both tracked, and all expressions are called in the sequence
  # implied by the dependency graph.
  
  output$plot_map <- renderLeaflet({
    province_input = input$Province
  
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
    
    google_canada <- read_csv("data/final_data.csv") ## Loading data
    
    library(forecast)
    library(leaflet)
    library(TTR)
    library(data.table)
    library(readr)
    library(tidyverse)
    library(DT)
    
    # combine to map
    provinces2  <- sp::merge(
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
    
    
    provinces2 %>%
      leaflet::leaflet() %>%
      leaflet(options = leafletOptions(zoomControl = FALSE,
                                       minZoom = 3, maxZoom = 3,
                                       dragging = FALSE)) %>%
      addTiles() %>%
      setView(-110.09, 62.7,  zoom = 3) %>%
      addPolygons(data = subset(provinces2, name %in% c("British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Québec", "New Brunswick", "Prince Edward Island", "Nova Scotia", "Newfoundland and Labrador", "Yukon", "Northwest Territories", "Nunavut")),
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
      
      addPolygons(data = subset(provinces2, name %in% c("British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Québec", "New Brunswick", "Prince Edward Island", "Nova Scotia", "Newfoundland and Labrador", "Yukon", "Northwest Territories", "Nunavut")),
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
      
      addPolygons(data = subset(provinces2, name %in% c("British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Québec", "New Brunswick", "Prince Edward Island", "Nova Scotia", "Newfoundland and Labrador", "Yukon", "Northwest Territories", "Nunavut")),
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
    
    