FROM rocker/geospatial:4.0.2

RUN git clone https://github.com/program--/covid-tracker.git 

WORKDIR covid-tracker 

RUN Rscript -e "install.packages('renv')"
RUN Rscript -e "renv::consent(provided = TRUE)"
RUN Rscript -e "renv::install(c(list.files('renv/library/R-4.0/x86_64-pc-linux-gnu/')[!(list.files('renv/library/R-4.0/x86_64-pc-linux-gnu/') %in% tibble::as_tibble(installed.packages())$Package)]))"

EXPOSE 17550

CMD Rscript covid-tracker/app.R