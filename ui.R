library(shinythemes)

fluidPage(
    theme = shinytheme("sandstone"),
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
