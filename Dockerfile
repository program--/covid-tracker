FROM rocker/geospatial:4.0.2

RUN git clone https://github.com/program--/covid-tracker.git 

WORKDIR covid-tracker

RUN Rscript -e 'install.packages("renv")'
RUN Rscript -e 'renv::consent(provided = TRUE)'

EXPOSE 8050

CMD Rscript -e 'renv::restore()' && Rscript app.R