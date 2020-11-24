FROM rocker/geospatial:4.0.2

RUN git clone https://github.com/program--/covid-tracker.git 

WORKDIR covid-tracker 

RUN Rscript -e "install.packages('renv')"
RUN Rscript -e "renv::consent(provided = TRUE)"
RUN Rscript -e "renv::restore()"

EXPOSE 17550

CMD Rscript app.R