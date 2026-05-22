library(terra)

if (file.exists("DESCRIPTION") && requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  library(evacpath)
}

out_dir <- file.path("_outputs", "function-example-check")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!interactive()) {
  pdf(file.path(out_dir, "function-example-check.pdf"), width = 10, height = 7)
  on.exit(dev.off(), add = TRUE)
}

pause <- function(label) {
  cat("\n\n---", label, "---\n")
  if (interactive()) readline("Press [enter] to continue...")
}

check_inside <- function(points, polygon) {
  inside <- relate(points, polygon, "intersects")
  c(total = nrow(points), inside = sum(inside), outside = sum(!inside))
}

oldpar <- par(no.readonly = TRUE)
on.exit(par(oldpar), add = TRUE)

# -------------------------------------------------------------------------
# 1. Build a small but realistic coastal example
# -------------------------------------------------------------------------

target_crs <- "EPSG:3857"

dem <- rast(
  nrows = 80,
  ncols = 120,
  xmin = 0,
  xmax = 6000,
  ymin = 0,
  ymax = 4000,
  crs = target_crs
)

xy <- crds(dem, df = TRUE)

# Offshore values are negative. Elevation rises inland with a low ridge and a
# shallow valley to make the least-cost surface visually meaningful.
values(dem) <-
  -2.5 +
  0.0011 * xy$x +
  0.00025 * xy$y +
  1.1 * exp(-((xy$x - 4200)^2 + (xy$y - 3000)^2) / 1200000) -
  0.8 * exp(-((xy$x - 2600)^2 + (xy$y - 1500)^2) / 600000)

inundation <- rast(dem)
values(inundation) <- ifelse(
  values(dem) > 0 & values(dem) < 2.8 & xy$x < 4300,
  1.2 + 0.0002 * (4300 - xy$x),
  0
)

roads <- vect(
  list(
    matrix(c(600, 800, 1900, 1200, 3200, 1500, 5200, 2200), ncol = 2, byrow = TRUE),
    matrix(c(800, 2600, 2100, 2300, 3600, 2500, 5600, 3300), ncol = 2, byrow = TRUE),
    matrix(c(1800, 500, 2100, 1500, 2150, 2600, 2300, 3800), ncol = 2, byrow = TRUE),
    matrix(c(3300, 600, 3350, 1600, 3500, 2600, 3800, 3700), ncol = 2, byrow = TRUE),
    matrix(c(500, 400, 800, 200), ncol = 2, byrow = TRUE)
  ),
  type = "lines",
  crs = target_crs
)
roads$name <- c("coastal road", "ridge road", "school access", "inland connector", "pier")
roads$kind <- c("road", "road", "road", "road", "pier")

# -------------------------------------------------------------------------
# Shared plotting extent and plotting helper
# -------------------------------------------------------------------------

# Every plot in this walkthrough uses the full synthetic DEM extent.
plot_extent <- ext(dem)
plot_xlim <- c(xmin(plot_extent), xmax(plot_extent))
plot_ylim <- c(ymin(plot_extent), ymax(plot_extent))

map_plot <- function(x, ..., add = FALSE) {
  if (add) {
    terra::plot(x, add = TRUE, ...)
  } else {
    terra::plot(
      x,
      ...,
      xlim = plot_xlim,
      ylim = plot_ylim,
      axes = FALSE,
      xlab = "",
      ylab = "",
      asp = 1
    )
  }
}

# -------------------------------------------------------------------------
# 1. Visualize input rasters
# -------------------------------------------------------------------------

par(
  mfrow = c(1, 2),
  mar = c(2, 2, 3, 5),
  las = 1,
  xaxs = "i",
  yaxs = "i"
)

map_plot(dem, main = "Synthetic Coastal DEM")
map_plot(inundation, main = "Synthetic Inundation Depth")

pause("Input rasters")

# -------------------------------------------------------------------------
# 2. prepare_hazard_zone()
# -------------------------------------------------------------------------

hazard_from_depth <- prepare_hazard_zone(inundation, threshold = 0, as_polygon = TRUE)
cat("Hazard polygons:", nrow(hazard_from_depth), "\n")

par(
  mfrow = c(1, 1),
  mar = c(2, 2, 3, 2),
  las = 1,
  xaxs = "i",
  yaxs = "i"
)

map_plot(
  hazard_from_depth,
  col = "#f28e2b99",
  border = NA,
  main = "prepare_hazard_zone()"
)
map_plot(roads, add = TRUE, col = "grey25", lwd = 1.2)

pause("prepare_hazard_zone")

# -------------------------------------------------------------------------
# 3. prepare_tsunami_zones()
# -------------------------------------------------------------------------

zones <- prepare_tsunami_zones(
  inundation = inundation,
  dem = dem,
  target_crs = target_crs,
  inundation_threshold = 0,
  dem_sign_multiplier = 1,
  as_polygon = TRUE,
  dissolve = TRUE
)

print(names(zones))

par(
  mfrow = c(2, 2),
  mar = c(2, 2, 3, 5),
  las = 1,
  xaxs = "i",
  yaxs = "i"
)

map_plot(zones$dem, main = "DEM")
map_plot(zones$land_mask, main = "Land Mask")
map_plot(
  zones$hazard_zone,
  col = "#f28e2b99",
  border = NA,
  main = "Land-Only Hazard Zone"
)
map_plot(
  zones$escape_zone,
  col = "grey90",
  border = "grey60",
  main = "Escape Zone: Hazard + Water"
)
map_plot(zones$hazard_zone, add = TRUE, col = "#f28e2b99", border = NA)

pause("prepare_tsunami_zones")

# -------------------------------------------------------------------------
# 4. clean_roads()
# -------------------------------------------------------------------------

roads_clean <- clean_roads(roads, exclude = list(field = "kind", values = "pier"))
cat("Roads before cleaning:", nrow(roads), "\n")
cat("Roads after cleaning:", nrow(roads_clean), "\n")

par(
  mfrow = c(1, 2),
  mar = c(2, 2, 3, 1),
  las = 1,
  xaxs = "i",
  yaxs = "i"
)

map_plot(
  roads,
  col = ifelse(roads$kind == "pier", "red", "grey30"),
  lwd = 2,
  main = "Before clean_roads()"
)
map_plot(
  roads_clean,
  col = "grey30",
  lwd = 2,
  main = "After clean_roads()"
)

pause("clean_roads")

# -------------------------------------------------------------------------
# 5. prepare_evac_inputs()
# -------------------------------------------------------------------------

inputs <- prepare_evac_inputs(
  hazard_zone = zones$hazard_zone,
  roads = roads_clean,
  dem = zones$dem,
  target_crs = target_crs
)

str(names(inputs))

pause("prepare_evac_inputs")

# -------------------------------------------------------------------------
# 6. make_evac_grid()
# -------------------------------------------------------------------------

evac_grid <- make_evac_grid(inputs$hazard_zone, resolution = 250)
cat("Evacuation grid cells:", nrow(evac_grid), "\n")

par(
  mfrow = c(1, 1),
  mar = c(2, 2, 3, 2),
  las = 1,
  xaxs = "i",
  yaxs = "i"
)

map_plot(
  inputs$hazard_zone,
  col = "grey95",
  border = "grey70",
  main = "make_evac_grid()"
)
map_plot(evac_grid, add = TRUE, border = "#4e79a7")
map_plot(inputs$roads, add = TRUE, col = "grey20", lwd = 1.1)

pause("make_evac_grid")

# -------------------------------------------------------------------------
# 7. find_escape_points(), crop_roads_to_inner_extent(), make_road_aware_escape_zone()
# -------------------------------------------------------------------------

roads_for_escape <- crop_roads_to_inner_extent(
  roads = inputs$roads,
  zone = zones$escape_zone,
  inset_x_m = 50,
  inset_y_m = 50
)

escape_boundary_zone <- make_road_aware_escape_zone(
  escape_zone = zones$escape_zone,
  roads = roads_for_escape,
  road_buffer_m = 40,
  crop_buffer_m = 80
)

escape_points <- find_escape_points(
  hazard_zone = escape_boundary_zone,
  roads = roads_for_escape
)

cat("Escape points:", nrow(escape_points), "\n")

map_plot(
  escape_boundary_zone,
  col = "grey92",
  border = "grey55",
  main = "Escape-Point Detection"
)
map_plot(zones$hazard_zone, add = TRUE, col = "#f28e2b80", border = NA)
map_plot(roads_for_escape, add = TRUE, col = "grey20", lwd = 1.1)
map_plot(escape_points, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.9)

pause("escape-point functions")

# -------------------------------------------------------------------------
# 8. make_region_area()
# -------------------------------------------------------------------------

study_area <- crop(zones$hazard_zone, ext(800, 3600, 500, 3000))
region_area <- make_region_area(zones$escape_zone, study_area, buffer_m = 700)

map_plot(
  zones$escape_zone,
  col = "grey95",
  border = "grey70",
  main = "make_region_area()"
)
map_plot(region_area, add = TRUE, col = "#4e79a755", border = "#4e79a7")
map_plot(study_area, add = TRUE, col = "#f28e2b99", border = NA)

pause("make_region_area")

# -------------------------------------------------------------------------
# 9. make_road_mask() and make_road_origins()
# -------------------------------------------------------------------------

mask_parts <- make_road_mask(
  roads = inputs$roads,
  escape_points = escape_points,
  road_buffer_m = 45,
  escape_buffer_m = 70,
  return_components = TRUE
)

road_points <- make_road_origins(
  evac_grid = evac_grid,
  roads_buffer = mask_parts$roads_buffer,
  hazard_zone = inputs$hazard_zone,
  max_origins = 40,
  seed = 42
)

cat("Road origins:\n")
print(check_inside(road_points, inputs$hazard_zone))

map_plot(
  inputs$hazard_zone,
  col = "grey95",
  border = "grey65",
  main = "Road Origins Inside Hazard Zone"
)
map_plot(mask_parts$roads_buffer, add = TRUE, col = "#bab0ab80", border = NA)
map_plot(inputs$roads, add = TRUE, col = "grey20", lwd = 0.8)
map_plot(road_points, add = TRUE, pch = 20, col = "#4e79a7", cex = 0.8)

pause("make_road_mask / make_road_origins")

# -------------------------------------------------------------------------
# 10. make_conductance_surface(), calculate_lc_path(), calculate_min_dist()
# -------------------------------------------------------------------------

conductance <- make_conductance_surface(
  dem = inputs$dem,
  road_mask = mask_parts$mask,
  resolution = 100
)

one_path <- calculate_lc_path(conductance, road_points[1, ], escape_points[1, ])
path_distance <- calculate_min_dist(list(one_path))
cat("Example least-cost path distance:", round(path_distance, 1), "map units\n")

map_plot(inputs$dem, main = "Single Least-Cost Path")
map_plot(mask_parts$mask, add = TRUE, col = "#ffffff55", border = NA)
map_plot(inputs$roads, add = TRUE, col = "grey20", lwd = 0.8)
map_plot(one_path, add = TRUE, col = "#4e79a7", lwd = 2)
map_plot(road_points[1, ], add = TRUE, pch = 20, col = "black", cex = 1.1)
map_plot(escape_points[1, ], add = TRUE, pch = 22, bg = "red", col = "black", cex = 1.1)

pause("conductance and least-cost path")

# -------------------------------------------------------------------------
# 11. calc_min_distance_to_safety(), calc_evac_time(), make_evac_polygons()
# -------------------------------------------------------------------------

distance_points <- calc_min_distance_to_safety(
  cs = conductance,
  origins = road_points,
  destinations = escape_points,
  progress = TRUE,
  progress_every = 10,
  check_locations = FALSE
)

distance_points$minutes <- calc_evac_time(distance_points$distance, walking_speed_mps = 1.22)

evac_polygons <- make_evac_polygons(
  distance_points = distance_points,
  clip_area = inputs$hazard_zone,
  walking_speed_mps = 1.22,
  region_name = "Synthetic coast"
)

cat("Distance/time points:", nrow(distance_points), "\n")
print(summary(evac_polygons$EvacTimeAvg))

map_plot(
  evac_polygons,
  "EvacTimeAvg",
  main = "Evacuation Time Polygons"
)
map_plot(inputs$roads, add = TRUE, col = "grey20", lwd = 0.6)
map_plot(escape_points, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.6)

pause("distance, time, polygons")

# -------------------------------------------------------------------------
# 12. run_evacpath() and write_evac_outputs()
# -------------------------------------------------------------------------

result <- run_evacpath(
  hazard_zone = inputs$hazard_zone,
  escape_zone = zones$escape_zone,
  roads = inputs$roads,
  roads_for_escape = roads_for_escape,
  dem = inputs$dem,
  target_crs = target_crs,
  region_name = "Synthetic coast",
  grid_resolution = 250,
  road_buffer_m = 45,
  escape_buffer_m = 70,
  final_road_buffer_m = 55,
  road_aware_escape_zone = TRUE,
  escape_zone_road_buffer_m = 40,
  escape_zone_crop_buffer_m = 80,
  max_origins = 40,
  max_destinations = 20,
  seed = 42,
  walking_speed_mps = 1.22,
  clip_mode = "hazard",
  progress = TRUE,
  progress_every = 10
)

cat("run_evacpath road origins:\n")
print(check_inside(result$road_points, result$hazard_zone))

paths <- write_evac_outputs(
  result,
  output_dir = out_dir,
  prefix = "synthetic_coast",
  include_inputs = TRUE,
  overwrite = TRUE
)

print(paths)

map_plot(
  result$time_grid,
  "EvacTimeAvg",
  main = "run_evacpath() Output"
)
map_plot(result$roads, add = TRUE, col = "grey20", lwd = 0.5)
map_plot(result$road_points, add = TRUE, pch = 20, col = "#4e79a7", cex = 0.65)
map_plot(result$escape_points, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.65)

cat("\nOutputs written to:\n", normalizePath(out_dir), "\n")

pause("run_evacpath / write_evac_outputs")