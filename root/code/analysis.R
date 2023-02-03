#' -------------------------------------------------------------------------
#' Project:     Pilot Project: Investigating Defect Growth
#'
#' Created by:  Stephen Bradshaw
#' Modified:    03/02/2023
#' Version:     1.0 -  
#'              1.1 - 
#'              1.2 - 
#'              
#'              
#' Purpose:     POC to identify track defect and track its growth across time
#'              Model growth to forcast time to threshold
#'              
#' -------------------------------------------------------------------------


#--> Packages ###
req_packages <- c('tidyverse', 'shiny', 'shinydashboard', 'DT', 'shinyjs', 'shinycssloaders', 'pool', 'logger',
                  'jsonlite', 'DBI', 'odbc', 'rmarkdown', 'plotly', 'zoo', 'sf', 'leaflet', 'leaflet.esri', 'dplyr',
                  'glue', 'colourpicker', 'lubridate', 'RColorBrewer', 'scales', 'assertthat', 'leaflegend')

sapply(req_packages, require, character.only = TRUE)

options(scipen = 999)
options(stringsAsFactors = FALSE)

source("src/query.R")
source("src/process.R")
source("src/plot.R")

USER <- if (Sys.getenv("SHINYPROXY_USERNAME") != "") {Sys.getenv("SHINYPROXY_USERNAME")} else {"Unauthenticated User"}

theme_set(theme_bw()) 

config <- jsonlite::read_json("bin/config.json")

wheel_region <- "DEV" # DEV, PRD

# wheel_region <- toupper(Sys.getenv("WHEEL_REGION"))

# note: Connection strings default to DEV environment. @fred 7/7/2022
W_CONN_STR <- ifelse(wheel_region == 'PRD', config$conn_str,
                     ifelse(wheel_region == 'UAT', config$uat_conn_str,
                            ifelse(wheel_region == 'DEV', config$dev_conn_str,
                                   toupper(ENV))))

w_pool    <- dbPool(odbc::odbc(), .connection_string = W_CONN_STR, timeout = 10)

shiny::onStop(function() {
  poolClose(w_pool)
})


#' @import bench
wall_clock <- function() {
  bench::hires_time()
}

elapsed_time_in_seconds <- function(start, end, decimals = 2) {
  paste(as.character(round(end - start, decimals)), "s")
}

##################

