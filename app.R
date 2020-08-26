library(tidyverse)
library(USAboundaries)
library(USAboundariesData)
library(sf)
library(shiny)
library(viridis)
library(readxl)

# Map theme edited from:
# https://timogrossenbacher.ch/2016/12/beautiful-thematic-maps-with-ggplot2-only/
library(showtext)
font_add_google("Ubuntu")
theme_map <- function(...) {
  theme_minimal() +
    theme(
      text = element_text(family = "Ubuntu", color = "#22211d"),
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.background = element_blank(),
      plot.title = element_text(hjust = 0.5, color = "#4e4d47", size = 24),
      panel.background = element_blank(),
      legend.background = element_rect(fill = "#f5f5f2", color = NA),
      legend.position = "bottom",
      panel.border = element_blank(),
      ...
    )
}

# Shiny Code
ui <- fluidPage(
  titlePanel("COVID-19 Tracker"),

  sidebarLayout(
    sidebarPanel(
      helpText(
        "Choose date and state to view county COVID-19 data on selected date."
      ),

      dateInput("dateIn",
                h3("Date"),
                label = "Choose a date",
                format = "yyyy-mm-dd"
      ),

      selectInput("stateIn",
                  h3("State"),
                  label = "Choose a state",
                  choices = as.list(state.name))
    ),
    mainPanel(plotOutput("plot", height = "800px"))
  )
)

server <- function(input, output) {

  source("load_data.R", local = TRUE)

  state_input <- reactive({
    filter(states, name == input$stateIn)
  })

  counties_input <- reactive({
    filter(
      counties_with_pop,
      state_name == input$stateIn & date == input$dateIn
    )
  })

  output$plot <- renderPlot({
    ggplot() +
      geom_sf(data = state_input()) +
      geom_sf(data = counties_input(), aes(fill = cases_per_capita)) +
      scale_fill_viridis(
        option = "viridis",
        direction = -1,
        name = "Confirmed COVID-19 Cases per Capita",
        trans = "log",
        guide = guide_colorbar(
          direction = "horizontal",
          barheight = unit(2, units = "mm"),
          barwidth = unit(50, units = "mm"),
          draw.ulim = F,
          title.position = "top",
          title.hjust = 0.5,
          label.hjust = 0.5)) +
      labs(
        title = input$stateIn,
        caption = "Source: NYTimes COVID-19 County Data") +
      theme_map()
  })
}

shinyApp(ui = ui, server = server, options = list(height = 1080))