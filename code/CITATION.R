
# Create CITIATION.bib file for repo -------------------------------------------

a <- ""
bibfiletext <- readLines(con = "https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/bibliography.bib")
for (ii in c("GAPProducts", "FOSSAFSCData")) {
  find_start <- grep(pattern = ii, x = bibfiletext, fixed = TRUE)
  find_end <- which(bibfiletext == "}")
  find_end <- find_end[find_end>find_start][1]
  aa <- bibfiletext[find_start:find_end]
  
  if (ii == "FOSSAFSCData") {
    link_foss <- aa[grep(pattern = "howpublished = {", x = aa, fixed = TRUE)]
    link_foss <- gsub(pattern = "howpublished = {", replacement = "", x = link_foss, fixed = TRUE)
    link_foss <- gsub(pattern = "},", replacement = "", x = link_foss, fixed = TRUE)
    link_foss <- trimws(link_foss)
  }
  
  a <- paste0(a, paste0("\n", aa, collapse = ""), "\n")
}
readr::write_file(x = paste0(a, collapse = "\n"), file = "CITATION.bib")
