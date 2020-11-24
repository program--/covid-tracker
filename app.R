library(dash)
library(dashCoreComponents)
library(dashHtmlComponents)
library(dashBootstrapComponents)
library(ggplot2)
library(plotly)

source("load_data.R")

states_lst <- list()
for (i in seq_len(length(state.name)) + 1) {
    states_lst[[i]] <-
        list(
            label = state.name[i],
            value = state.name[i]
        )
}

states_lst[[1]] <-
    list(
        label = "All",
        value = "ALL"
    )
counties <- rjson::fromJSON(file = "https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json")

max_date <- max(readRDS("data/counties_with_pop.rds")$Date)

app <- Dash$new(external_stylesheets = list(dbcThemes$COSMO, "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.1/css/all.min.css"))

app$title("COVID-19 Information")

# State Dropdown
state_dropdown <-
    dbcFormGroup(
        list(
            dbcLabel("State", html_for = "stateDropdown", width = 2),
            dbcCol(
                dccDropdown(
                    id = "stateDropdown",
                    options = states_lst,
                    value = states_lst[[1]]$value,
                    multi = TRUE
                )
            )
        )
    )

metric_dropdown <-
    dbcFormGroup(
        list(
            dbcLabel("Metric", html_for = "metricDropdown", width = 2),
            dbcCol(
                dccDropdown(
                    id = "metricDropdown",
                    options = list(
                        list(label = "Cases", value = "C"),
                        list(label = "Cases Per Capita", value = "CPC")
                    ),
                    value = "C"
                )
            )
        )
    )

# Date Picker
date_picker <-
    dbcFormGroup(
        list(
            dbcLabel("Date", html_for = "datePicker", width = 2),
            dbcCol(
                dccDatePickerSingle(
                    id = "datePicker",
                    date = as.Date(max_date - 1, "%Y-%m-%d"),
                    max_date_allowed = as.Date(max_date, "%Y-%m-%d")
                )
            )
        )
    )

# Forms
form <- dbcForm(list(date_picker, state_dropdown, metric_dropdown))

# Table function
generate_table <- function(df, nrows=10) {

    rows <- lapply(
        1: min(nrows, nrow(df)),
        function(i) {
            htmlTr(children = lapply(as.character(df[i,]), htmlTd))
        }
    )

    header <- htmlTr(
        children = lapply(
            c("County", "Cases Per Capita", "Cases", "Deaths"),
            htmlTh
        )
    )

    dbcTable(
        children = c(list(header), rows)
    )
}

app$layout(
    htmlDiv(
        list(
            dccInterval(
                id = "update-data",
                interval = 86400 * 1000 # 1 day
            ),
            dbcModal(
                list(
                    dbcContainer(
                        list(
                            htmlH5("About", className = "modal-title"),
                            dbcButton(
                                className = "fas fa-times float-right rounded",
                                color = "dark",
                                id = "close"
                            )
                        ),
                        className = "modal-header"
                    ),
                    dbcModalBody(
                        list(
                            "Built with ",
                            htmlB(
                                htmlA("Dash", href = "https://plotly.com/dash/")
                            ),
                            ".",
                            htmlBr(),
                            "Data sourced from ",
                            htmlB(
                                htmlA("NYTimes COVID-19 Data", href = "https://github.com/nytimes/covid-19-data")
                            ),
                            ".",
                            htmlBr(),
                            htmlBr(),
                            htmlA("Source Code", href = "https://github.com/program--/covid-tracker")
                        )
                    )
                ),
                id = "about-modal",
                is_open = FALSE
            ),
            dbcNavbarSimple(
                list(
                    dbcNavItem(
                        dbcNavLink(
                            "About",
                            href = "#",
                            id = "about"
                        )
                    ),
                    dbcNavItem(
                        dbcNavLink(
                            href = "https://github.com/nytimes/covid-19-data",
                            id = "updated"
                        )
                    )
                ),
                brand = "COVID-19 Historical Data",
                brand_href = "#",
                color = "dark",
                dark = TRUE
            ),
            dbcContainer(
                list(
                    dbcRow(
                        list(
                            dbcCol(
                                list(
                                    form,
                                    dbcAlert(
                                        list(
                                            htmlH5("Note:", className = "alert-heading"),
                                            "The map will run faster if all of the USA ",
                                            htmlB("is not"),
                                            " selected."
                                        ),
                                        dismissable = TRUE,
                                        color = "info"
                                    )
                                ),
                                width = 3
                            ),
                            dbcCol(
                                dccLoading(
                                    children = htmlDiv(id = "output"),
                                    type = "graph"
                                ),
                                width = 9
                            )
                        ),
                        className = "m-2"
                    ),
                    dbcRow(
                        list(
                            dbcCol(
                                list(
                                    htmlH4("Top 5 Counties by Metric"),
                                    htmlDiv(id = "table_output")
                                )
                            )
                        )
                    )
                )
            ),
            dbcCardFooter(
                dbcContainer(
                    dbcRow(
                        list(
                            dbcCol(
                                dbcListGroup(
                                    list(
                                        dbcListGroupItemHeading(htmlB("Wear a Mask")),
                                        dbcListGroupItemText(htmlI(className = "fas fa-head-side-mask fa-7x")),
                                        dbcListGroupItemHeading(htmlB("Stop the Spread"))
                                    ),
                                    className = "text-center"
                                )
                            ),
                            dbcCol(
                                dbcListGroup(
                                    list(
                                        dbcListGroupItemHeading("Important COVID-19 Information"),
                                        dbcListGroupItem("CDC", href = "https://www.cdc.gov/coronavirus/2019-ncov/index.html"),
                                        dbcListGroupItem("World Health Organization", href = "https://www.who.int/emergencies/diseases/novel-coronavirus-2019"),
                                        dbcListGroupItem("Find a Testing Site", href = "https://www.hhs.gov/coronavirus/community-based-testing-sites/index.html")
                                    ),
                                    className = "text-center"
                                )
                            ),
                            dbcCol(
                                dbcListGroup(
                                    list(
                                        dbcListGroupItemHeading("More COVID-19 Statistics"),
                                        dbcListGroupItem("CDC Data Tracker", href = "https://covid.cdc.gov/covid-data-tracker/#cases_casesper100klast7days"),
                                        dbcListGroupItem("NYTimes COVID Map", href = "https://www.nytimes.com/interactive/2020/us/coronavirus-us-cases.html"),
                                        dbcListGroupItem("John Hopkins University COVID Map", href = "https://coronavirus.jhu.edu/us-map")
                                    ),
                                    className = "text-center"
                                )
                            )
                        )
                    )
                ),
                className = "fixed-bottom text-muted"
            )
        )
    )
)

app$callback(
    output = list(id = "updated", property = "children"),
    params = list(input(id = "update-data", property = "n_intervals")),
    function(n_int) {
        if (max_date != Sys.Date() - 1) {
            write_covid()
        }

        return(paste0("Updated: ", as.character(Sys.Date())))
    }
)

app$callback(
    output = list(id = "about-modal", property = "is_open"),
    params = list(
        input(id = "about", property = "n_clicks"),
        input(id = "close", property = "n_clicks"),
        state(id = "about-modal", property = "is_open")
    ),
    function(n1, n2, is_open) {
        if (is.null(n1[[1]])) one <- 0 else one <- n1
        if (is.null(n2[[1]])) two <- 0 else two <- n2

        if (one | two) {
            return(!is_open)
        }

        return(is_open)
    }
)

app$callback(
    output = list(id = "table_output", property = "children"),
    params = list(
        input(id = "stateDropdown", property = "value"),
        input(id = "datePicker", property = "date"),
        input(id = "metricDropdown", property = "value")
    ),
    function(value, date, metric) {
        dataset <- sf::st_as_sf(readRDS("data/counties_with_pop.rds")) %>%
        sf::st_drop_geometry() %>%
        tibble::as_tibble()

        if (value == "ALL" | is.null(value)) {
            dataset <- dplyr::filter(
                dataset,
                Date == as.Date(date, "%Y-%m-%d")
            )
        } else {
            dataset <- dplyr::filter(
                dataset,
                state_name %in% value,
                Date == as.Date(date, "%Y-%m-%d")
            )
        }

        if (metric == "C") {
            return(
                generate_table(
                    dplyr::arrange(dataset, -cases) %>%
                    dplyr::select(name, cases_per_capita, cases, deaths),
                    nrows = 5
                )
            )
        } else {
            return(
                generate_table(
                    dplyr::arrange(dataset, -cases_per_capita) %>%
                    dplyr::select(name, cases_per_capita, cases, deaths),
                    nrows = 5
                )
            )
        }
    }
)

app$callback(
    output = list(id = "output", property = "children"),
    params = list(
        input(id = "stateDropdown", property = "value"),
        input(id = "datePicker", property = "date"),
        input(id = "metricDropdown", property = "value")
    ),
    function(value, date, metric) {
        dataset <- sf::st_as_sf(readRDS("data/counties_with_pop.rds"))

        if (value == "ALL" | is.null(value[[1]])) {
            dataset <- dplyr::filter(
                dataset,
                Date == as.Date(date, "%Y-%m-%d")
            )
        } else {
            dataset <- dplyr::filter(
                dataset,
                state_name %in% value,
                Date == as.Date(date, "%Y-%m-%d")
            )
        }

        bbox <- sf::st_bbox(dataset$geometry)

        fig <- plot_ly()

        if (metric == "C") {
            fig <- fig %>%
                   add_trace(
                       type = "choropleth",
                       geojson = counties,
                       locations = dataset$fips,
                       z = dplyr::if_else(
                               is.infinite(
                                   log(dataset$cases)
                               ),
                               0,
                               log(dataset$cases)
                       ),
                       colorscale = "Viridis",
                       marker = list(line = list(width = 0))
                   ) %>%
                   colorbar(title = "Cases")
        } else if (metric == "CPC") {
            fig <- fig %>%
                   add_trace(
                       type = "choropleth",
                       geojson = counties,
                       locations = dataset$fips,
                       z = dplyr::if_else(
                               is.infinite(
                                   log(dataset$cases_per_capita)
                               ),
                               0,
                               log(dataset$cases_per_capita)
                       ),
                       colorscale = "Viridis",
                       marker = list(line = list(width = 0))
                   ) %>%
                   colorbar(title = "Cases Per Capita")
        }

        fig <- fig %>%
               layout(
                   geo = list(
                       scope = "usa",
                       projection = list(type = "albers usa"),
                       showlakes = TRUE,
                       lakecolor = toRGB("white"),
                       projection_scale = 8,
                       center = list(
                           lat = (bbox[[4]] + bbox[[2]]) / 2,
                           lon = (bbox[[3]] + bbox[[1]]) / 2
                       )
                   )
               )

        return(dccGraph(id = "graph-output", figure = fig, className = "border"))
    }
)


app$run_server()