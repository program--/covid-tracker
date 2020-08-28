function(input, output) {
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
