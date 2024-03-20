#' Calculate difference between two numeric vectors.
#' Function to calculate absolute difference between two vectors
#' @param v1 Numeric vector. The first vector
#' @param v2 Numeric vector. The second vector from which to compare v1. 
#' @param percent Boolean. Should the difference be presented as an absolute
#'                 percent difference relative to v2? Defaults to TRUE. 
#'                 
#' @returns Numeric vector of differences.

calc_diff <- function(v1, v2, percent = T) {
  
  df <- data.table::data.table("v1" = v1, 
                               "v2" = v2,
                               "DIFF" = v1 - v2)
  data.table::setnames(x = df, c("v1", "v2", "DIFF"))
  
  df[, v2 := ifelse(test = v2 == 0, 1, v2)]
  df[, PERC_DIFF := DIFF / v2]
  
  return(df[, ifelse(percent == T, "PERC_DIFF", "DIFF"), with = F])
}
