library(shiny)
library(leaflet)

shinyUI(pageWithSidebar(
        headerPanel("On The Bisons Tracks!"),
        sidebarPanel(
                h3("Selection Panel"),
                dateInput("chosendate","Please select a date in 2013:", value = "2013-05-15"),
                helpText("Please wait for the map to appear"),
                h5("Travel characteristics:"),
                checkboxInput('travbox', 'Cumulative distance'),
                checkboxInput('speedbox', 'Average speed'),
                helpText("Please scroll down to see the plots"),
                img(src="American_bison.jpg", height = 161.4, width = 247.5)
        ),
        mainPanel(
                tabsetPanel(
                        tabPanel("Tracking data",
                                 verbatimTextOutput("replicateddate"),
                                 h4("Bisons trajectories in the Dunn Ranch Prairie"),
                                 leafletOutput("mymap"),
                                 plotOutput("travdist")
                                 ), 
                        tabPanel("Documentation",
                                 includeMarkdown("include.md")
                                 )
                )
        )
        )
)