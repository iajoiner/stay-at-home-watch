# declare-source ----------------------------------------------------------

options(shiny.sanitize.errors = TRUE)
# -------------------------------------------------------------------------

# run shiny UI
library(shiny)
library(DT)

# Define UI for random distribution app ----
ui <- fluidPage(theme="shiny.css",
                
                # App title ----
                titlePanel("Stay-at-Home-Watch"),
                p("The data in these visualisations are from the ", 
                  href = "https://www.google.com/covid19/mobility/")
                )

                tabsetPanel(
                  type = "tabs",
                  tabPanel("Mobility",
                             sidebarPanel(
                               p("Relative proportions of mobility in Canadian Provinces"),
                               # Input: Select the random distribution type ----
                               radioButtons(inputId ="Province",
                                            label ="Select Province: ",
                                            c("Alberta" = "Alberta", 
                                              "British Columbia" = "British Columbia",
                                              "Manitoba" = "Manitoba",
                                              "New Brunswick" = "New Brunswick",
                                              "Newfoundland and Labrador" = "Newfoundland and Labrador",
                                              "Nova Scotia" = "Nova Scotia",
                                              "Ontario" = "Ontario",
                                              "Quebec" = "Quebec",
                                              "Saskatchewan" = "Saskatchewan"),
                                            selected = "British Columbia",
                                            inline = FALSE,
                                            width = NULL),
                               ),
                  ))





