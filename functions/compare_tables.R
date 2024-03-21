#' Table comparison function
#' Function to inventory the  
#' @param x Dataframe. Merged Table containing the full join of two tables.
#'          The format of these tables is very important and specific to this
#'          analysis. The fields contained in the `key columns` argument 
#'          need to be present. The columns to check in argument 
#'          `cols_to_check` should also be in `x` and should be suffixed by the
#'          arguments `base_table_suffix` and `update_table_suffix`. For 
#'          example, if `cols_to_check$colname = "POPULATION_COUNT"`,   
#'          `base_table_suffix = "_CURRENT"` and 
#'          `update_table_suffix = "_UPDATE"`, then the columns
#'          "POPULATION_COUNT_CURRENT" and "POPULATION_COUNT_UPDATE" should be 
#'          in `x`.
#' @param key_columns Character vector. The key name(s) of `x`. Must be present
#'                    in `x`.
#' @param cols_to_check Dataframe. Must have these three columns: 1) colname:
#'                      column names to compare (without suffixes), 2) percent:
#'                      Boolean, should the differences be presented in 
#'                      percent (=TRUE) or absolute (=FALSE) values, and 3)
#'                      decplaces: the number of decimal places to calculate
#'                      differences. This is also the minimum tolerance for a 
#'                      difference. 
#' @param base_table_suffix Character vector. Suffix of the base table.
#' @param update_table_suffix Character vector. Suffix of the new table.
#'                 
#' @returns List with three slots for 1) new records, 2) removed records, and 
#'          3) modified records. 

compare_tables <- function(x = NULL, 
                           key_columns = NULL,
                           cols_to_check = NULL, 
                           base_table_suffix = NULL,
                           update_table_suffix = NULL) {
  
  for (iarg in c("x", "cols_to_check", "base_table_suffix", 
                 "update_table_suffix", "key_columns")) 
    if (is.null(x = get(iarg))) stop("Please provide argument: `", iarg, "`")
  
  if (!is.data.frame(x = cols_to_check)) 
    stop("Argument `cols_to_check` must be a dataframe")
  
  if (!all(names(x = cols_to_check) %in% c("colname", "percent", "decplaces"))) 
    stop("Argument cols_to_check must have names: c('colname', 'percent')")
  
  check_these_names <- 
    do.call(what = c, 
            args = sapply(X = paste0(cols_to_check$colname), 
                          FUN = function(x) paste0(x, c(base_table_suffix, 
                                                        update_table_suffix)),
                          simplify = F))
  
  if (!all(check_these_names %in% names(x = x))) 
    stop("Check that all the column in `x` to compare have both suffixes")
  
  if (!all(key_columns %in% names(x = x))) 
    stop("The `key_columns` need to be present in argument `x`")
  
  col_order <- 
    as.vector(t(sapply(X = c(base_table_suffix, update_table_suffix, "_DIFF"),
                       FUN = function(x) paste0(cols_to_check$colname, x), 
                       simplify = T)))
  
  for (icol in 1:nrow(x = cols_to_check)) {
    x[, paste0(cols_to_check$colname[icol], "_DIFF") := 
      round(x = calc_diff(v1 = x[, paste0(cols_to_check$colname[icol], 
                                          base_table_suffix), with = F],
                          v2 = x[, paste0(cols_to_check$colname[icol], 
                                          update_table_suffix), with = F],
                          percent = cols_to_check$percent[icol]) ,
            digits = cols_to_check$decplaces[icol])]
  }

  new_records_stmt <- 
    paste0("x[",
           paste0(sapply(X = cols_to_check$colname, 
                         FUN = function(x) 
                           paste0("(is.na(x = ", x, base_table_suffix, 
                                  ") & !is.na(x = ", x, update_table_suffix, 
                                  "))")), 
                  collapse = "|"), 
           "]")
  new_records <- eval(parse(text = new_records_stmt))
  new_records <- new_records[, c(key_columns, col_order), with = F]
  
  if (nrow(x = new_records) > 0) new_records$NOTE <- ""
  
  removed_records_stmt <- 
    paste0("x[",
           paste0(sapply(X = cols_to_check$colname, 
                         FUN = function(x) 
                           paste0("(!is.na(x = ", x, base_table_suffix, 
                                  ") & is.na(x = ", x, update_table_suffix, 
                                  "))")), 
                  collapse = "|"), 
           "]")
  removed_records <- eval(parse(text = removed_records_stmt))
  removed_records <- removed_records[, c(key_columns, col_order), with = F]

  if (nrow(x = removed_records) > 0) removed_records$NOTE <- ""
  
  modified_records_stmt <- 
    paste0("x[",
           paste0(sapply(X = cols_to_check$colname, 
                         FUN = function(x) 
                           paste0(x, "_DIFF != 0")), 
                  collapse = " | "), 
           "]")
  modified_records <- eval(parse(text = modified_records_stmt))
  modified_records <- modified_records[, c(key_columns, col_order), with = F]
  
  if (nrow(x = modified_records) > 0) modified_records$NOTE <- ""

    
  return(do.call(what = list,
                 args = list(new_records = new_records, 
                             removed_records = removed_records, 
                             modified_records = modified_records)))
}
