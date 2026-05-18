# Example workflow ---------------------------------------------------
# This is a compact version of the diagnostic workflow. For full QA/QC, see
# diagnostic-example.Rmd or vignettes/diagnostic-example.Rmd.

library(terra)
library(evacpath)

# ---- Raw data --------------------------------------------------------------
tsunami <- rast("_data/raw/inundation.nc")
dem <- rast("_data/raw/topo.nc")
roads <- vect("_data/raw/road.shp")

target_crs <- "EPSG:32748"

# ---- Example-specific preprocessing ---------------------------------------
# Change dem_sign_multiplier to -1 if your topobathymetry sign convention is
# reversed relative to land > 0 and water < 0.
zones <- prepare_tsunami_zones(
  inundation = tsunami,
  dem = dem,
  target_crs = target_crs,
  dem_sign_multiplier = 1,
  inundation_threshold = 0
)

roads <- clean_roads(
  roads,
  exclude = list(field = "man_made", values = "pier"),
  target_crs = target_crs
)

# Crop roads used only for escape-point detection to avoid artificial study-area
# edge intersections, then include buffered road corridors in the escape boundary.
roads_for_escape <- crop_roads_to_inner_extent(
  roads = roads,
  zone = zones$escape_zone,
  inset_x_m = 250,
  inset_y_m = 250
)

escape_boundary_zone <- make_road_aware_escape_zone(
  escape_zone = zones$escape_zone,
  roads = roads_for_escape,
  road_buffer_m = 2,
  crop_buffer_m = 3
)

escape_points <- find_escape_points(
  hazard_zone = escape_boundary_zone,
  roads = roads_for_escape
)

# ---- Full evacuation workflow ---------------------------------------------
result <- run_evacpath(
  hazard_zone = zones$hazard_zone,
  escape_zone = zones$escape_zone,
  roads = roads,
  dem = zones$dem,
  target_crs = target_crs,
  region_name = "Example region",
  grid_resolution = terra::res(zones$dem) * 50,
  dem_resolution = terra::res(zones$dem) * 50,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  final_road_buffer_m = 3,
  escape_roads_inset_x_m = 250,
  escape_roads_inset_y_m = 250,
  road_aware_escape_zone = TRUE,
  seed = 23401,
  walking_speed_mps = 1.22,
  clip_mode = "hazard",
  progress = TRUE
)

plot(result$time_grid, "EvacTimeAvg", border = NA)
plot(result$escape_points, add = TRUE, pch = 22, bg = "red", col = "black")

write_evac_outputs(
  result,
  output_dir = "_outputs/example",
  prefix = "example"
)
