#===================================================================#
#            BASE IMAGE: R, Security Certs, SQL Drivers             #
#===================================================================#

FROM rocker/r-ver:4.1.1 as base

## Install Aurizon Security Certificates
COPY .devcontainer/certs/* /usr/local/share/ca-certificates/
RUN /usr/sbin/update-ca-certificates

## Install SQL/ODBC Drivers and their System dependencies
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1au.\2/" /etc/apt/sources.list \
    && apt-get update -qq && apt-get -y --no-install-recommends install \
        curl \
        gnupg2 \
        apt-utils \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \ 
        msodbcsql17 \
        unixodbc \
        unixodbc-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


#===================================================================#
#                         PRODUCTION IMAGE                          #
#===================================================================#

FROM base as prd

## Install OS Dependencies
RUN apt-get update && apt-get install -y  \
        git-core \
        libcurl4-openssl-dev \
        libgdal-dev \
        libgeos-dev \
        libgit2-dev \
        libicu-dev \
        libssl-dev \
        libproj-dev \
        libudunits2-dev \
        libxml2-dev \
        pandoc \
        pandoc-citeproc \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

## Install R Packages
RUN install2.r --error --skipinstalled --ncpus -1 \
        remotes \
    && rm -rf /tmp/downloaded_packages 

# Copy app package to image and install
RUN mkdir /build_zone
ADD CA/ /build_zone
WORKDIR /build_zone
RUN R -e 'remotes::install_local(dependencies=TRUE, upgrade="never")'

# Set prod env variable
ENV GOLEM_CONFIG_ACTIVE 'production'
# TODO(fred): Review New Relic set up here
ENV NEW_RELIC_APP_NAME 'ConditionAnalyzer-ui-prod'
ENV NEW_RELIC_DAEMON_HOST 'bnedevdsc701:31339'  
# Set version = latest git tag
ARG VERSION='Unassigned'
ENV VERSION=$VERSION
ENV BALLAST_REGION 'DEV'
ENV RAIL_REGION 'DEV'

# Run Shiny App on port 3838
EXPOSE 3838
CMD  ["R", "-e", "options('shiny.port'=3838,shiny.host='0.0.0.0');CA::run_app()"]

