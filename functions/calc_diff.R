#' Calculate difference between two numeric vectors.
#' Function to calculate absolute difference between two vectors
#' @param v1 Numeric vector. The first vector
#' @param v2 Numeric vector. The second vector from which to compare v1. 
#' @param percent Boolean. Should the difference be presented as an absolute
#'                 percent difference relative to v2? Defaults to TRUE. 
#'                 
#' @returns Numeric vector of differences.

calc_diff <- function(v1, v2, percent = T) {
  
  ## Calculate absolute differences between v1 and v2
  difference <- abs(x = v1 - v2)
  
  if (percent) # Calculate percent difference
    difference <- 100 * difference / 
      # To avoid a NaN from dividing by zero, the ifelse statement is added. 
      ifelse(test = v2 == 0, 
             yes = 1,
             no = v2)
  
  return(difference)
}
