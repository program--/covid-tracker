FROM virtualstaticvoid/heroku-docker-r:shiny


RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
    liblwgeom-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev

RUN wget https://raw.githubusercontent.com/eddelbuettel/littler/master/inst/examples/install2.r

RUN install2.r --error \
    RColorBrewer \
    RandomFields \
    RNetCDF \
    classInt \
    deldir \
    gstat \
    hdf5r \
    lidR \
    mapdata \
    maptools \
    mapview \
    ncdf4 \
    proj4 \
    raster \
    rgdal \
    rgeos \
    rlas \
    sf \
    sp \
    spacetime \
    spatstat \
    spdep \
    geoR \
    geosphere \
    tidyverse \

# fix proj issue on singularity  
RUN echo 'PROJ_LIB=/usr/share/proj/' >> /usr/lib/R/etc/Renviron

ENV PORT=8080
CMD ["/usr/bin/R", "--no-save", "--gui-none", "-f", "/app/run.R"]

