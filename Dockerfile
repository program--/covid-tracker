FROM rocker/geospatial

ENV PORT=8080

# install shiny
RUN /usr/bin/R --no-save --quiet --slave -e "install.packages('shiny', clean=TRUE, quiet=TRUE, verbose=FALSE)"

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
