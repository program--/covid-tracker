FROM rocker/geospatial:4.0.2

RUN Rscript -e 'install.packages("renv")'
RUN Rscript -e 'renv::consent(provided = TRUE)'

EXPOSE 8050

CMD git clone https://github.com/program--/covid-tracker.git && cd covid-tracker && Rscript -e 'renv::restore()' && Rscript app.R