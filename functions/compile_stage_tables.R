#' Internal Function to Create Stage Tables for Oracle
#' 

compile_stage_tables <- function(update_list = NULL) {
  if (is.null(x = update_list) | !is.list(x = update_list)) 
    stop ("Must provide a named list for `update_list`")
  
  
  regions <- c("AI", "GOA", "EBS", "BSS", "NBS")
  all_tables <- c("cpue", "biomass", "sizecomp", "agecomp")
  
  for (itable in all_tables) { ## loop over tables -- start
    
    stage_table_name <- paste0("STAGE_", toupper(x = paste0(itable)))
    assign(x = paste0("STAGE_", toupper(x = paste0(itable))),
           value = data.frame()) 
    
    for (iregion in regions) { ## loop over region -- start
      
      ## Extract the key values of the table
      key_values <- data.table::key(update_list[[iregion]][[itable]][["new_records"]])
      
      ## Compile inserted rows
      new_records <- update_list[[iregion]][[itable]][["new_records"]]
      op_type <- "INSERT"
      response_values <- grep(pattern =  "_UPDATE", 
                              x = names(x = new_records), 
                              value = TRUE) 
      
      temp_table <- 
        cbind(OPERATION = rep(op_type, nrow(new_records)),
              new_records[, c(key_values, response_values), with = F])
      
      names(x = temp_table) <- 
        gsub(x = names(x = temp_table), pattern = "_UPDATE", replacement = "")
      
      ## append new records to the stage table
      assign(x = stage_table_name,
             value = rbind(get(stage_table_name), temp_table))
      
      ## Compile updated rows
      modified_records <- update_list[[iregion]][[itable]][["modified_records"]]
      op_type <- "UPDATE"
      response_values <- grep(pattern =  "_UPDATE", 
                              x = names(x = modified_records), 
                              value = TRUE) 
      
      temp_table <- 
        cbind(OPERATION = rep(op_type, nrow(modified_records)),
              modified_records[, c(key_values, response_values), with = F])
      
      names(x = temp_table) <- 
        gsub(x = names(x = temp_table), pattern = "_UPDATE", replacement = "")
      
      ## append new records to the stage table
      assign(x = stage_table_name,
             value = rbind(get(stage_table_name), temp_table))
      
      ## Compile deleted records
      deleted_records <- update_list[[iregion]][[itable]][["removed_records"]]
      op_type = "DELETE"
      response_values <- grep(pattern =  "_CURRENT", 
                              x = names(x = deleted_records), 
                              value = TRUE) 
      
      temp_table <- 
        cbind(OPERATION = rep(op_type, nrow(deleted_records)),
              deleted_records[, c(key_values, response_values), with = F])
      
      names(x = temp_table) <- 
        gsub(x = names(x = temp_table), pattern = "_CURRENT", replacement = "")
      
      ## append new records to the stage table
      assign(x = stage_table_name,
             value = rbind(get(stage_table_name), temp_table))
    } ## loop over region -- end
  } ## loop over tables -- end
  
  return(list(STAGE_CPUE = STAGE_CPUE, 
              STAGE_BIOMASS = STAGE_BIOMASS, 
              STAGE_SIZECOMP = STAGE_SIZECOMP, 
              STAGE_AGECOMP = STAGE_AGECOMP))
}
