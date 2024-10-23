#' Summarize changed records in Oracle
#' 
#' @description Tabulate the number of INSERT, DELETE, UPDATE values by region
#' and year for GAP_PRODUCTS tables CPUE, BIOMASS, SIZECOMP, and AGECOMP.
#' 

summarize_gp_updates <- function(channel = NULL,
                                 time_start = NULL,
                                 time_end = NULL) {
  
  ## Checks on time range formats
  if (is.null(x = time_start)) stop("Must provide time_start.")
  parsed_date <- strptime(time_start, "%d-%b-%y %I.%M.%S %p")
  if (is.na(x = parsed_date)) stop("Must provide time_start in format 'dd-MON-YY HH.MM.SS AM/PM', e.g., 08-SEP-24 12.00.00 PM")
    
  if (is.null(x = time_end)) time_end <-
      format(x = Sys.time(), format = "%d-%b-%y %I.%M.%S %p")
  parsed_date <- strptime(time_end, "%d-%b-%y %I.%M.%S %p")
  if (is.na(x = parsed_date)) stop("Must provide time_start in format 'DD-MON-YY HH.MM.SS AM/PM', e.g., 08-SEP-24 12.00.00 PM")
  
  ## Stitch together SQL query
  sql_query <- paste0(
    ## CPUE audit records
    "SELECT 'CPUE' AS TABLE_NAME, OPERATION_TYPE, 
     SURVEY_DEFINITION_ID, YEAR, COUNT(*) NUMBER_RECS
FROM GAP_ARCHIVE.AUDIT_CPUE
JOIN (SELECT HAULJOIN, CRUISEJOIN 
      FROM GAP_PRODUCTS.AKFIN_HAUL) 
     USING (HAULJOIN)
JOIN (SELECT CRUISEJOIN, SURVEY_DEFINITION_ID, YEAR 
      FROM GAP_PRODUCTS.AKFIN_CRUISE) 
      USING (CRUISEJOIN)
  WHERE OPERATION_TIMESTAMP BETWEEN '", time_start, "' AND '", time_end, "'",
    "\nGROUP BY OPERATION_TYPE, SURVEY_DEFINITION_ID, YEAR",
    
    ## Biomass audit records
    "\n\nUNION\n\n" ,
    "SELECT 'BIOMASS' AS TABLE_NAME, OPERATION_TYPE, 
       SURVEY_DEFINITION_ID, YEAR, COUNT(*) NUMBER_RECS
FROM GAP_ARCHIVE.AUDIT_BIOMASS
WHERE OPERATION_TIMESTAMP BETWEEN '", time_start, "' AND '", time_end, "'",
    "\nGROUP BY OPERATION_TYPE, SURVEY_DEFINITION_ID, YEAR",
    
    ## Sizecomp audit records
    "\n\nUNION\n\n" ,
    "SELECT 'SIZECOMP' AS TABLE_NAME, OPERATION_TYPE, 
       SURVEY_DEFINITION_ID, YEAR, COUNT(*) NUMBER_RECS
FROM GAP_ARCHIVE.AUDIT_SIZECOMP
WHERE OPERATION_TIMESTAMP BETWEEN '", time_start, "' AND '", time_end, "'",
    "\nGROUP BY OPERATION_TYPE, SURVEY_DEFINITION_ID, YEAR",
    
    ## Agecomp audit records
    "\n\nUNION\n\n" ,
    "SELECT 'AGECOMP' AS TABLE_NAME, OPERATION_TYPE, 
       SURVEY_DEFINITION_ID, YEAR, COUNT(*) NUMBER_RECS
FROM GAP_ARCHIVE.AUDIT_AGECOMP
WHERE OPERATION_TIMESTAMP BETWEEN '", time_start, "' AND '", time_end, "'",
    "\nGROUP BY OPERATION_TYPE, SURVEY_DEFINITION_ID, YEAR")
  
  return(RODBC::sqlQuery(channel = channel,
                         query = sql_query))
}

