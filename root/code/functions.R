
#' A very simple cache function so we don't recompute large tables in the global scope
#' 
#' @return A simple cache that can get/set some value base on a key.
simple_cache <- function() {
  e <- new.env(parent = emptyenv())
  
  list(
    get = function(key) {
      if (exists(key, envir = e, inherits = FALSE)) {
        return(e[[key]])
      } else {
        return(structure(list(), class = "key_missing"))
      }
    },
    set = function(key, value) {
      e[[key]] <- value
    }
  )
}
sc <- simple_cache()


mutex <- synchronicity::boost.mutex()

# NOTE(fred): just some fun statistics 14/7/2022
m_cache_hits <- 0
m_cache_miss <- 0

get_query <- function(fname, conn, query) {
  
  key <- query
  synchronicity::lock(mutex)
  result <- sc$get(key)
  synchronicity::unlock(mutex)
  
  is_cached <- (is.key_missing(result) == FALSE)
  
  # TODO(fred): find a way that represent the actual data stored in the simple cache (or use another cache with eviction scheme) 15/7/2022
  cache_size <- format(object.size(sc), units = "auto", standard = "IEC")
  start <- wall_clock()
  
  if (is_cached == TRUE) {
    m_cache_hits <<- m_cache_hits + 1
    log_debug(paste0("cache[hit]  (h/m/t): ",
                     paste(m_cache_hits, m_cache_miss, m_cache_hits + m_cache_miss, sep = "/"),
                     " [", cache_size, "]", ", fn: ", fname, ", t_query: ", elapsed_time_in_seconds(start, wall_clock(), decimals = 3)))
  } else {
    m_cache_miss <<- m_cache_miss + 1
    result <- dbGetQuery(conn, query)
    log_debug(paste0("cache[miss] (h/m/t): ",
                     paste(m_cache_hits, m_cache_miss, m_cache_hits + m_cache_miss, sep = "/"),
                     " [", cache_size, "]", ", fn: ", fname, ", t_query: ", elapsed_time_in_seconds(start, wall_clock(), decimals = 3)))
    
    # Cache the result
    sc$set(key, result)
  }
  
  log_trace(paste0("query:\n-- begin [[\n", query, "\n-- end ]]\n\n"))
  
  return(result)
}

#' #' Global Wheel Wear data from ODMS
#' #'
#' #' @return data.frame
#' #'
#' #' @examples get_wheel_wear()
#' get_wheel_wear <- function() {
#'   query <- "SELECT TOP(1000) * FROM [ODMS].[Reliability].[WheelWear]"
#'   
#'   conn <- pool::poolCheckout(w_pool)
#'   result <- get_query("dat_wheel_wear", conn, query)
#'   pool::poolReturn(conn)
#'   
#'   return(result)
#' }

#' Global Wheel Wear summary data from ODMS
#'
#' @return data.frame
#'
#' @examples get_wheel_summary
get_wheel_summary <- function() {
#   query <- "SELECT *,
#             YEAR(ComplianceChangeDate) AS ComplianceChangeYear
#             FROM [ODMS].[Reliability].[WheelWear]
#             WHERE SourceFileDateTime = (SELECT MAX(SourceFileDateTime) 
# 						FROM [ODMS].[Reliability].[WheelWear])
#               AND IsLatest = 1"
  
  query <- "SELECT * FROM [DataScience].[dbo].[vw_WheelwearSummary]"
  
  conn <- pool::poolCheckout(w_pool)
  result <- get_query("dat_wheel_summary", conn, query)
  pool::poolReturn(conn)
  
  return(result)
  
}

#' Global data for filters based on summary table from ODMS
#'
#' @return data.frame
#'
#' @examples get_wheel_wear_summary()
get_wheel_wear_summary <- function() {
  query <- "SELECT * FROM [DataScience].[Reliability].[WheelWearSummary]"
  
  conn <- pool::poolCheckout(w_pool)
  result <- get_query("dat_wheel_wear_summary", conn, query)
  pool::poolReturn(conn)
  
  return(result)
  
}

# get_latest_wheel_wear_data <- function(){
#   
#   query <- "SELECT *
#             FROM [DataScience].[Reliability].[WheelWearDetail]
#             WHERE wc_monday = (SELECT MAX(wc_monday) 
# 						  FROM  [DataScience].[Reliability].[WheelWearDetail]) 
#               AND is_latest = 1 "
#   
#   conn <- pool::poolCheckout(w_pool)
#   result <- get_query("dat_latest_wheel_wear", conn, query)
#   pool::poolReturn(conn)
#   
#   return(result)
#   
# }

#' Get wheel wear data based on Plant Maintenance, Vehicle class and Vehicle Number
#'
#' @return data.frame
#'
#' @examples get_wheel_wear_focus()
get_wheel_wear_focus <- function(plant_text, veh_class, veh_no) {
  
  conn <- pool::poolCheckout(w_pool)
  
  query <-  glue::glue_sql("SELECT * FROM [DataScience].[Reliability].[WheelWearDetail]
                            WHERE planning_plant_text = {plant_text} AND
	                                fleet_vehicle_class = {veh_class} AND
	                                fleet_vehicle_no = {veh_no}", .con = conn)
  
  result <- get_query("get_wheel_wear_focus", conn, query)
  pool::poolReturn(conn)
  
  return(result)
}