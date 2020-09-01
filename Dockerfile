FROM rocker/geospatial

RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    xtail \
    wget


# Download and install shiny server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    . /etc/environment && \
    R -e "install.packages(c('shiny', 'rmarkdown'), repos='$MRAN')" && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ && \
    chown shiny:shiny /var/lib/shiny-server

EXPOSE 8080

COPY shiny-server.sh /usr/bin/shiny-server.sh

# on build, copy application files
ONBUILD COPY . /app

# on build, for installing additional dependencies etc.
ONBUILD RUN if [ -f "/app/onbuild" ]; then bash /app/onbuild; fi;

# on build, for backward compatibility, look for /app/Aptfile and if it exists, install the packages contained
ONBUILD RUN if [ -f "/app/Aptfile" ]; then apt-get update -q && cat Aptfile | xargs apt-get -qy install && rm -rf /var/lib/apt/lists/*; fi;

# on build, for backward compatibility, look for /app/init.R and if it exists, execute it
ONBUILD RUN if [ -f "/app/init.R" ]; then /usr/bin/R --no-init-file --no-save --quiet --slave -f /app/init.R; fi;

# on build, packrat restore packages
# NOTE: packrat itself is packaged in this same structure so will be bootstrapped here
ONBUILD RUN if [ -f "/app/packrat/init.R" ]; then /usr/bin/R --no-init-file --no-save --quiet --slave -f /app/packrat/init.R --args --bootstrap-packrat; fi;

# on build, renv restore packages
ONBUILD RUN if [ -f "/app/renv/activate.R" ]; then /usr/bin/R --no-save --quiet --slave -e 'renv::restore()'; fi;

ENV PORT=8080

# CMD ["/usr/bin/shiny-server.sh"]
CMD ["/usr/bin/R", "--no-save", "--gui-none", "-f", "/app/run.R"]

