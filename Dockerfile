# Base image, see https://hub.docker.com/r/rocker/rstudio

FROM rocker/tidyverse:4.0.4
USER root
RUN apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y libssl-dev libffi-dev && \
    apt-get install -y vim && \
    apt-get install -y -t unstable \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev/unstable \
    libxt-dev && \
    wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    R -e "install.packages(c('shiny', 'flexdashboard'))" && \
    R -e 'if(!require(devtools)) { install.packages("devtools") }; library(devtools);' && \
    R -e "library(devtools); install_cran('plotly')" && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    apt-transport-https \
    cron \
    nano \
    curl \
    gnupg \
    unixodbc \
    && install2.r odbc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*
#install git
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --assume-yes git
# Disable host verification
RUN git config --global http.sslVerify false
#Install Cran    
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    DBI odbc \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds    
ENV USER rstudio
RUN apt-get install -y iodbc libiodbc2-dev libssl-dev
COPY ./deploy_snowflake.sh /
RUN chmod +x /deploy_snowflake.sh
RUN odbc_version=2.23.2 jdbc_version=3.12.10 snowsql_version=1.2.15 /deploy_snowflake.sh
WORKDIR /home/$USER/
COPY .odbc.ini /home/rstudio/



