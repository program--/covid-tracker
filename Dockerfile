FROM rocker/geospatial:4.0.2

RUN git clone https://github.com/program--/covid-tracker.git \
    cd covid-tracker \
    Rscript -e "install.packages('renv')" \
    Rscript -e "renv::load()" \

EXPOSE 17550

CMD ["Rscript app.R"]