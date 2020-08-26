library(tidyverse)
library(USAboundaries)
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

# Getting USA data
states <- USAboundaries::us_states() %>%
  st_transform(5070)

usa_outline <- states %>%
  st_union() %>%
  st_cast("MULTILINESTRING")

url = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"
covid <- read_csv(url)

counties <- USAboundaries::us_counties() %>%
  select(name, state_name, geometry) %>%
  right_join(covid,
             by = c("name" = "county", "state_name" = "state")) %>%
  st_transform(5070)

population_dir = "data/PopulationEstimates.xls"
population_estimates <- readxl::read_excel(population_dir)
names(population_estimates) <- population_estimates[2, ] # Set headers
population_estimates <- population_estimates[-c(1:2), ] # Remove first two rows
state_list <- data.frame(
  State_Full = state.name,
  State = state.abb
)
population_estimates <- population_estimates %>%
  mutate(Area_Name = str_remove_all(Area_Name, regex(".County"))) %>%
  left_join(state_list, by = "State")

counties_with_pop <- population_estimates %>%
  select(State_Full, Area_Name, POP_ESTIMATE_2019, POP_ESTIMATE_2018) %>%
  setNames(c("state_name",
    "name",
    "population_estimate_2019",
    "population_estimate_2018")) %>%
  right_join(counties, by = c("state_name", "name")) %>%
  # Use 2019 estimates; if returns NA, then use 2018 estimates.
  mutate(
    cases_per_capita = if_else(
      is.na(cases / as.double(population_estimate_2019)),
      cases / as.double(population_estimate_2019),
      cases / as.double(population_estimate_2018))) %>%
  st_as_sf()

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
                value = as.Date(max(covid$date), format = "%Y-%m-%d"),
                min = as.Date(min(covid$date), format = "%Y-%m-%d"),
                max = as.Date(max(covid$date), format = "%Y-%m-%d"),
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