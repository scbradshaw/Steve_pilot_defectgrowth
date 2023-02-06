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
#'  
#search all to identify regions which are at 8.6 of threshold
#subset those regions across all times
#subset and microalign
#plot image to show peak change
#apply crude predictive fitting
#'  
#'  
#'              
#' -------------------------------------------------------------------------

#### INITIAL PREPARATION ####
#--> Packages ####
req_packages <- c('tidyverse', 'shiny', 'shinydashboard', 'DT', 'shinyjs', 'shinycssloaders', 'pool', 'logger',
                  'jsonlite', 'DBI', 'odbc', 'rmarkdown', 'plotly', 'zoo', 'sf', 'leaflet', 'leaflet.esri', 'dplyr',
                  'glue', 'colourpicker', 'lubridate', 'RColorBrewer', 'scales', 'assertthat', 'leaflegend'
                  ,'synchronicity', 'bench')


#' Packages ---------------------------------------------------------------
new.packages <- req_packages[!(req_packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)


#' Libraries ---------------------------------------------------------------
sapply(req_packages,require,character.only = TRUE, quietly=TRUE)


#--> Options ####
options(scipen = 999)
options(stringsAsFactors = FALSE)

source("src/functions.R")

# USER <- if (Sys.getenv("SHINYPROXY_USERNAME") != "") {Sys.getenv("SHINYPROXY_USERNAME")} else {"Unauthenticated User"}

theme_set(theme_bw()) 

config <- jsonlite::read_json("bin/config.json")
# config

# #--> [BLOCKED] Connection Stuff ####
#' 
#' wheel_region <- "DEV" # DEV, PRD
#' 
#' # note: Connection strings default to DEV environment. @fred 7/7/2022
#' W_CONN_STR <- ifelse(wheel_region == 'PRD', config$conn_str,
#'                      ifelse(wheel_region == 'UAT', config$uat_conn_str,
#'                             ifelse(wheel_region == 'DEV', config$dev_conn_str,
#'                                    toupper(ENV))))
#' 
#' w_pool    <- dbPool(odbc::odbc(), .connection_string = W_CONN_STR, timeout = 10)
#' 
#' shiny::onStop(function() {
#'   poolClose(w_pool)
#' })
#' 
#' 
#' #' @import bench
#' wall_clock <- function() {
#'   bench::hires_time()
#' }
#' 
#' elapsed_time_in_seconds <- function(start, end, decimals = 2) {
#'   paste(as.character(round(end - start, decimals)), "s")
#' }
# #--> [BLOCKED] Source Data ####
# # df <- get_geom_data('BW-01ML',0,10000,5)
# saveRDS(df, paste("data/BW-01ML",sep=""))
# #####


#### INVESTIGATION ####
#--> Load Test Data #####
getwd()
setwd("data")
df <- readRDS(dir()[1])
setwd("..")


#### Wrangle ####
#--> Change format #### 
tdf <- melt(df, id = c("RouteId","MeasurementPosition", "ThroughMetreBin", "Kilometre", "Metre", "MeasurementDate")) 
tdf <- tdf %>% na.omit() 
tdf <- tdf %>% unite('param', c("MeasurementPosition", "variable"), remove=TRUE)
tdf$param <- tdf$param %>% str_remove_all("Percentile")

head(tdf)
tail(tdf)

#--> Split on Record date ####
datestouse <- tdf$MeasurementDate %>% unique() %>% as.character()
ldf <- tdf %>% group_split(MeasurementDate)
names(ldf) <- datestouse

lapply(ldf, head)

#####


#### Analysis Case Study ####

lapply(ldf, head)



#--> Select Param of interest ####




#--> Filter for a value near threshold (across all times) ####





#--> Subset sections and microalign #####





#--> Display Visually ####






#--> Prediction ####


















