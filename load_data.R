library(dplyr)
library(sf)
library(viridis)
library(readxl)
library(USAboundaries)
library(USAboundariesData)

# Getting USA data
us_states_map <- function() {
    states <- USAboundaries::us_states()

    return(states)
}

us_outline_map <- function() {
    usa_outline <- us_states_map() %>%
                   st_union() %>%
                   st_cast("MULTILINESTRING")

    return(usa_outline)
}

us_counties_covid <- function(covid) {
    counties <- USAboundaries::us_counties() %>%
                select(name, state_name, geometry) %>%
                right_join(
                    covid,
                    by = c("name" = "county", "state_name" = "state")
                )

    return(counties)
}

write_pop_dataset <- function() {
    # Pre-shrinking dataset
    population_dir <- "data/PopulationEstimates.xls"

    population_estimates <- readxl::read_excel(population_dir)

    # Set headers
    population_estimates <- setNames(
        population_estimates,
        population_estimates[2, ]
    )

    population_estimates <- population_estimates[-c(1:2), ] # Remove first two rows

    state_list <- data.frame(
        State_Full = state.name,
        State = state.abb
    )

    population_estimates <-
        population_estimates %>%
        mutate(Area_Name = str_remove_all(Area_Name, regex(".County"))) %>%
        left_join(state_list, by = "State") %>%
        select(State_Full, Area_Name, POP_ESTIMATE_2019, POP_ESTIMATE_2018)

    write.csv(population_estimates, "data/population_estimates.csv")
}

write_covid <- function() {
    url <- dplyr::if_else(
               file.exists("data/us-counties.csv"),
               "data/us-counties.csv",
               "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"
           )

    covid <- readr::read_csv(url)

    counties <- us_counties_covid(covid)

    if (!file.exists("data/population_estimates.csv")) write_pop_dataset()

    population_dir <- "data/population_estimates.csv"
    population_estimates <- readr::read_csv(population_dir)[, -1]

    counties_with_pop <-
        population_estimates %>%
        select(State_Full, Area_Name, POP_ESTIMATE_2019, POP_ESTIMATE_2018) %>%
        setNames(
            c(
                "state_name",
                "name",
                "population_estimate_2019",
                "population_estimate_2018"
            )
        ) %>%
        right_join(counties, by = c("state_name", "name")) %>%
        mutate(
            cases_per_capita = if_else(
                is.na(cases / as.double(population_estimate_2019)),
                cases / as.double(population_estimate_2019),
                cases / as.double(population_estimate_2018)
            )
        ) %>%
        rename(Date = date) %>%
        st_as_sf()

    saveRDS(counties_with_pop, "data/counties_with_pop.rds")
}
