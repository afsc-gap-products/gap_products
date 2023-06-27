

library(ggplot2)
library(viridis)
library(akgfmaps)
library(sf)

shp_ebs <- akgfmaps::get_base_layers(select.region = "bs.south", set.crs = "auto")
shp_nbs <- akgfmaps::get_base_layers(select.region = "bs.north", set.crs = "auto")
shp_ai <- akgfmaps::get_base_layers(select.region = "ai", set.crs = "auto")
shp_goa <- akgfmaps::get_base_layers(select.region = "goa", set.crs = "auto")
shp_bss <- akgfmaps::get_base_layers(select.region = "ebs.slope", set.crs = "auto")

shp <- dplyr::bind_rows(list(
  shp_ebs$survey.area %>% 
    sf::st_transform(crs = "EPSG:3338") %>% 
    dplyr::mutate(SURVEY = "EBS"), 
  shp_nbs$survey.area  %>% 
    sf::st_transform(crs = "EPSG:3338") %>% 
    dplyr::mutate(SURVEY = "NBS"), 
  shp_ai$survey.area %>% 
    sf::st_transform(crs = "EPSG:3338") %>% 
    dplyr::mutate(SURVEY = "AI"), 
  shp_goa$survey.area %>% 
    sf::st_transform(crs = "EPSG:3338") %>% 
    dplyr::mutate(SURVEY = "GOA"), 
  shp_bss$survey.area %>% 
    sf::st_transform(crs = "EPSG:3338") %>% 
    dplyr::mutate(SURVEY = "BSS"))) %>% 
  dplyr::select(Survey = SURVEY, geometry)

gg <- ggplot() +
  ggplot2::geom_sf(data = shp_bss$akland, 
                   fill = "dark grey", 
                   color = "transparent") + 
  ggplot2::geom_sf(data = shp_nbs$graticule,
                   color = "grey90", 
                   size = 0.5, 
                   alpha = 0.5) +
  ggplot2::geom_sf(data = shp_ai$graticule,
                   color = "grey90",
                   size = 0.5, 
                   alpha = 0.5) +
  ggplot2::geom_sf(data = shp_goa$graticule,
                   color = "grey90",
                   size = 0.5, 
                   alpha = 0.5) +
  ggplot2::scale_x_continuous(name = "Longitude",
                              breaks = c(-180, -170, -160, -150, -140)) + # shp_bss$lon.breaks) +
  # ggplot2::scale_y_continuous(name = "Latitude", breaks = shp_bss$lat.breaks) +
  ggplot2::ggtitle(label = "Bottom Trawl Survey Regions",
                   subtitle = "AFSC RACE Groundfish and Shellfish Public Data Coverage") +
  ggplot2::theme_classic() + 
  ggplot2::theme(
    panel.background = element_rect(fill = "transparent"), #grey95
    plot.title = element_text(size = 20, face = "bold"), 
    plot.subtitle = element_text(size=14), 
    legend.text=element_text(size=8), 
    legend.position="right",
    legend.direction="vertical",
    legend.justification="left",
    legend.background = element_blank(),
    legend.title=element_text(size=14),
    axis.text = element_text(size=10), 
    legend.box.background = element_blank(),
    legend.key = element_blank(), 
    legend.key.size=(unit(.3,"cm")), 
    axis.title=element_text(size=14), 
    plot.margin = margin(0,0,0,0,unit = "cm")) +
  ggplot2::geom_sf(data = shp, 
                   mapping = aes(fill = Survey),
                   color = "grey20", 
                   show.legend = TRUE) +
  ggplot2::scale_fill_viridis_d(option = "G", end = 0.9, begin = 0.1) +
  ggplot2::coord_sf(xlim = c(-1394658,  2566293), # range(shp_ai$plot.boundary$x, shp_bs$plot.boundary$x, shp_goa$plot.boundary$x, shp_bss$plot.boundary$x),
                    ylim = c(-1028565.1,  1125549.7)) # range(shp_ai$plot.boundary$y, shp_bs$plot.boundary$y, shp_goa$plot.boundary$y, shp_bss$plot.boundary$y))

ggsave(filename = "survey_plot.png", 
       plot = gg,
       path = here::here("img"), 
       width = 7, 
       height = 3)

tocTF <- TRUE
rmarkdown::render(input = here::here("docs","README.Rmd"),
                  output_dir = here::here(),
                  output_format = 'md_document',
                  output_file = here::here("README.md"))

# Make README into index
index <- base::readLines(con = here::here("docs","README.Rmd"))
utils::write.table(x = index,
                   file = here::here("docs","index.Rmd"),
                   row.names = FALSE,
                   col.names = FALSE,
                   quote = FALSE)


comb <- list.files(path = "docs/", pattern = ".Rmd", ignore.case = TRUE)
comb <- comb[comb != "footer.Rmd"]
comb <- gsub(pattern = ".Rmd", replacement = "", x = comb, ignore.case = TRUE)

tocTF <- FALSE
## Loop over pages
for (jj in 1:length(comb[comb != "README"])) { 
  rmarkdown::render(
    input = here::here("docs", paste0(comb[jj], ".Rmd")),
    output_dir = here::here("docs"),
    output_file = paste0(comb[jj], ".html") )
}
