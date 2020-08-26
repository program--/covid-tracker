withProgress(message = "Processing Data", value = 0, {
    n <- 5

    incProgress(1 / n, detail = "Getting USA Spatial Data...")

    # Getting USA data
    states <<- USAboundaries::us_states() %>%
    st_transform(5070)

    usa_outline <<- states %>%
    st_union() %>%
    st_cast("MULTILINESTRING")

    incProgress(1 / n, detail = "Getting USA COVID-19 Data...")
    url = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"
    covid <<- readr::read_csv(url)

    incProgress(1 / n, detail = "Processing USA COVID-19 Data...")
    counties <<- USAboundaries::us_counties() %>%
    select(name, state_name, geometry) %>%
    right_join(covid,
                by = c("name" = "county", "state_name" = "state")) %>%
    st_transform(5070)

    # Pre-shrinking dataset
    # population_dir = "data/PopulationEstimates.xls"
    # population_estimates <- readxl::read_excel(population_dir)
    # population_estimates <- setNames(population_estimates, population_estimates[2, ]) # Set headers
    # population_estimates <- population_estimates[-c(1:2), ] # Remove first two rows
    # state_list <- data.frame(
    #   State_Full = state.name,
    #   State = state.abb
    # )
    # population_estimates <- population_estimates %>%
    #   mutate(Area_Name = str_remove_all(Area_Name, regex(".County"))) %>%
    #   left_join(state_list, by = "State") %>%
    #   select(State_Full, Area_Name, POP_ESTIMATE_2019, POP_ESTIMATE_2018)
    # write.csv(population_estimates, "data/population_estimates.csv")

    incProgress(1 / n, detail = "Getting Population Data...")
    population_dir <- "data/population_estimates.csv"
    population_estimates <<- readr::read_csv(population_dir)

    incProgress(1 / n, detail = "Processing Population Data...")
    counties_with_pop <<- population_estimates %>%
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

})