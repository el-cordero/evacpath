# Generate simple README figures from the packaged example data.
#
# The packaged rasters are stored in lon/lat, but the README figures use the
# projected workflow CRS. The requested display window is interpreted as UTM
# easting/northing coordinates:
#   x: 669000 to 675000
#   y: 9223000 to 9225000

library(terra)

if (file.exists("DESCRIPTION") && requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  library(evacpath)
}

target_crs <- "EPSG:32748"
readme_extent <- ext(669000, 675000, 9223000, 9225000)
output_dir <- file.path("man", "figures")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

focus_area <- as.polygons(readme_extent, crs = target_crs)

dem_raw <- rast(system.file("extdata/dem.tif", package = "evacpath"))
roads_raw <- vect(system.file("extdata/rds.gpkg", package = "evacpath"))
inundation_raw <- rast(system.file("extdata/tsunami_inundation_depth.tif", package = "evacpath"))

# Crop the raw source data first, before preparing zones or running the model.
focus_area_source <- project(focus_area, crs(dem_raw))
dem <- crop(dem_raw, focus_area_source)
inundation <- crop(inundation_raw, focus_area_source)
roads_raw <- crop(roads_raw, focus_area_source)

zones <- prepare_tsunami_zones(
  inundation = inundation,
  dem = dem,
  target_crs = target_crs,
  inundation_threshold = 0,
  dem_sign_multiplier = 1,
  as_polygon = TRUE,
  dissolve = TRUE
)

roads <- clean_roads(
  roads_raw,
  exclude = list(field = "man_made", values = "pier"),
  target_crs = target_crs
)

hazard_zone <- crop(zones$hazard_zone, readme_extent)
escape_zone <- crop(zones$escape_zone, readme_extent)
dem <- crop(zones$dem, readme_extent)
roads <- crop(roads, readme_extent)

roads_for_escape <- crop_roads_to_inner_extent(
  roads = roads,
  zone = escape_zone,
  inset_x_m = 0,
  inset_y_m = 0
)

escape_boundary_zone <- make_road_aware_escape_zone(
  escape_zone = escape_zone,
  roads = roads_for_escape,
  road_buffer_m = 2,
  crop_buffer_m = 3
)

escape_points <- find_escape_points(
  hazard_zone = escape_boundary_zone,
  roads = roads_for_escape
)

escape_points_window <- crop(escape_points, readme_extent)

png(
  filename = file.path(output_dir, "readme-example-inputs.png"),
  width = 1400,
  height = 700,
  res = 180
)
par(mar = c(3, 3, 3, 1), mgp = c(1.8, 0.6, 0), las = 1, bg = "white")
plot(
  escape_zone,
  ext = readme_extent,
  col = "grey94",
  border = "grey70",
  main = "Example Hazard Zone, Roads, and Escape Points",
  cex.main = 1.1,
  axes = TRUE
)
plot(hazard_zone, add = TRUE, col = "#f28e2b99", border = NA)
plot(roads, add = TRUE, col = "#333333", lwd = 0.5)
plot(escape_points_window, add = TRUE, pch = 22, bg = "#e15759", col = "black", cex = 0.7)
dev.off()

result <- run_evacpath(
  hazard_zone = hazard_zone,
  escape_zone = escape_zone,
  roads = roads,
  dem = dem,
  target_crs = target_crs,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  final_road_buffer_m = 3,
  escape_roads_inset_x_m = 0,
  escape_roads_inset_y_m = 0,
  road_aware_escape_zone = TRUE,
  max_origins = 500,
  max_destinations = 100,
  seed = 23401,
  walking_speed_mps = 1.22,
  clip_mode = "hazard",
  progress = FALSE
)

time_window <- crop(result$time_grid, readme_extent)
result_roads_window <- crop(result$roads, readme_extent)
result_escape_window <- crop(result$escape_points, readme_extent)

png(
  filename = file.path(output_dir, "readme-example-time.png"),
  width = 1400,
  height = 700,
  res = 180
)
par(mar = c(3, 3, 3, 5), mgp = c(1.8, 0.6, 0), las = 1, bg = "white")
plot(
  time_window,
  "EvacTimeAvg",
  ext = readme_extent,
  col = hcl.colors(7, "YlOrRd", rev = TRUE),
  border = NA,
  main = "Example Modeled Evacuation Time",
  cex.main = 1.1,
  plg = list(title = "Minutes", cex = 0.8, title.cex = 0.85)
)
plot(result_roads_window, add = TRUE, col = "#33333380", lwd = 0.35)
plot(result_escape_window, add = TRUE, pch = 22, bg = "#e15759", col = "black", cex = 0.65)
dev.off()
