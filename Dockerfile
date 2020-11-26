FROM rocker/geospatial:4.0.2

# Setup renv
RUN Rscript -e 'install.packages("renv")'
RUN Rscript -e 'renv::consent(provided = TRUE)'

# Clone app from GitHub and set WORKDIR
WORKDIR ~
RUN git clone https://github.com/program--/covid-tracker.git
WORKDIR covid-tracker

# Setup cronjob to download COVID-19 data from NYTimes' repo every day
RUN service cron start
RUN (crontab -l ; echo "0 5 * * * /usr/bin/wget https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv -O /covid-tracker/data/us-counties.csv") | crontab

# Download packages (workaround for build memory issues) and run app
CMD  Rscript -e 'renv::restore()' && Rscript app.R