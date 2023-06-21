
bibfiletext <- readLines(con = "https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/bibliography.bib")
find_start <- grep(pattern = "GAPProducts", x = bibfiletext, fixed = TRUE)
find_end <- which(bibfiletext == "}")
find_end <- find_end[find_end>find_start][1]
a <- bibfiletext[find_start:find_end]
readr::write_file(x = paste0(a, collapse = "\n"), file = "CITATION.bib")
