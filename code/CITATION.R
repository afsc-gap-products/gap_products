
# Create CITIATION.bib file for repo -------------------------------------------

a <- ""
bibfiletext <- readLines(con = "https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/bibliography.bib")
for (ii in c("GAPProducts", "FOSSAFSCData", "GAPakfin")) {
  find_start <- grep(pattern = ii, x = bibfiletext, fixed = TRUE)
  find_end <- which(bibfiletext == "}")
  find_end <- find_end[find_end>find_start][1]
  aa <- bibfiletext[find_start:find_end]
  
  # if (ii == "FOSSAFSCData") {
  #   link_foss <- aa[grep(pattern = "howpublished = {", x = aa, fixed = TRUE)]
  #   link_foss <- gsub(pattern = "howpublished = {", replacement = "", x = link_foss, fixed = TRUE)
  #   link_foss <- gsub(pattern = "},", replacement = "", x = link_foss, fixed = TRUE)
  #   link_foss <- trimws(link_foss)
  # }
  
  readr::write_file(x = paste0(aa, collapse = "\n"), 
                    file = here::here("code", paste0("CITATION_",ii,".bib")))
  a <- paste0(a, paste0("\n", aa, collapse = ""), "\n")
  
}

readr::write_file(x = paste0(a, collapse = "\n"), file = "CITATION.bib")


# create local bib and csl files -----------------------------------------------

library(RCurl)
# library(XML)

utils::write.table(
  x = getURL("https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/bibliography.bib"),
                   file = here::here("content","references.bib"),
                   row.names = FALSE,
                   col.names = FALSE,
                   quote = FALSE)

utils::write.table(
  x = getURL("https://raw.githubusercontent.com/citation-style-language/styles/master/apa-no-ampersand.csl"),
  file = here::here("content","references.csl"),
  row.names = FALSE,
  col.names = FALSE,
  quote = FALSE)

