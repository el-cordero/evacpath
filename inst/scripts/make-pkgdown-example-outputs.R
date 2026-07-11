# Generate compact, reviewable pkgdown example outputs from packaged data.
# Run this script from the package root after changing the example workflow.

if (!file.exists("DESCRIPTION")) {
  stop("Run this script from the evacpath package root.", call. = FALSE)
}

library(terra)

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  library(evacpath)
}

target_crs <- "EPSG:32748"
focus_extent <- ext(669000, 675000, 9223000, 9225000)
figure_dir <- file.path("man", "figures")
data_dir <- file.path("inst", "extdata")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

focus_polygon <- as.polygons(focus_extent, crs = target_crs)
dem_raw <- rast(system.file("extdata/dem.tif", package = "evacpath"))
roads_raw <- vect(system.file("extdata/rds.gpkg", package = "evacpath"))
inundation_raw <- rast(system.file(
  "extdata/tsunami_inundation_depth.tif",
  package = "evacpath"
))

# Crop raw inputs before preparing zones or calculating routes.
source_focus <- project(focus_polygon, crs(dem_raw))
dem <- crop(dem_raw, source_focus)
roads_raw <- crop(roads_raw, source_focus)
inundation <- crop(inundation_raw, source_focus)

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

hazard_zone <- crop(zones$hazard_zone, focus_extent)
escape_zone <- crop(zones$escape_zone, focus_extent)
dem <- crop(zones$dem, focus_extent)
roads <- crop(roads, focus_extent)

roads_for_escape <- crop_roads_to_inner_extent(
  roads = roads,
  zone = escape_zone,
  inset_x_m = 0,
  inset_y_m = 300
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
escape_points <- crop(escape_points, focus_extent)

run_args <- list(
  hazard_zone = hazard_zone,
  escape_zone = escape_zone,
  roads = roads_for_escape,
  dem = dem,
  target_crs = target_crs,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  final_road_buffer_m = 3,
  escape_roads_inset_x_m = 0,
  escape_roads_inset_y_m = 0,
  road_aware_escape_zone = TRUE,
  max_origins = 40,
  max_destinations = 12,
  seed = 23401,
  walking_speed_mps = 1.22,
  clip_mode = "hazard",
  progress = FALSE,
  keep_routes = TRUE
)

# Individual origin-exit pairs can be disconnected in this small road network.
# The workflow retains the minimum reachable route for each sampled origin.
result <- suppressWarnings(do.call(run_evacpath, run_args))

road_distances <- terra::values(result$distance_points)
road_distances <- road_distances[road_distances$type == "road", , drop = FALSE]
road_times <- calc_evac_time(
  road_distances$distance,
  walking_speed_mps = result$parameters$walking_speed_mps
)

input_summary <- data.frame(
  metric = c(
    "Coordinate reference system",
    "Hazard-zone area (square km)",
    "Road features",
    "Candidate safety exits",
    "Sampled road origins"
  ),
  value = c(
    target_crs,
    format(round(sum(terra::expanse(hazard_zone, unit = "km")), 3), nsmall = 3),
    nrow(roads),
    nrow(result$escape_points),
    nrow(result$road_points)
  ),
  stringsAsFactors = FALSE
)

time_summary <- data.frame(
  metric = c(
    "Minimum modeled time (minutes)",
    "Median modeled time (minutes)",
    "Mean modeled time (minutes)",
    "Maximum modeled time (minutes)",
    "Origins",
    "Destinations",
    "Walking speed (m/s)"
  ),
  value = c(
    round(min(road_times), 2),
    round(stats::median(road_times), 2),
    round(mean(road_times), 2),
    round(max(road_times), 2),
    nrow(result$road_points),
    nrow(result$escape_points),
    result$parameters$walking_speed_mps
  ),
  stringsAsFactors = FALSE
)

scenario_args <- run_args
scenario_args$max_origins <- 25
scenario_args$max_destinations <- 8
scenario_args$keep_routes <- FALSE

comparison <- suppressWarnings(do.call(
  compare_evac_scenarios,
  c(
    list(
      scenarios = list(
        baseline = list(walking_speed_mps = 1.22),
        slow_walkers = list(walking_speed_mps = 0.75),
        conservative_routing = list(lcp_neighbours = 8, lcp_max_slope = 30)
      ),
      quiet = TRUE
    ),
    scenario_args
  )
))

scenario_summary <- comparison$summary
scenario_summary$note <- c(
  "Baseline walking-speed and routing assumptions.",
  "Changes time conversion; route distance is held by the same routing setup.",
  "Uses 8 neighbours and a 30 percent maximum slope."
)

bottlenecks <- tryCatch(
  map_evac_bottlenecks(
    evac_result = result,
    quantile_threshold = 0.9,
    return_polygons = TRUE
  ),
  error = function(e) NULL
)

diagnostics <- diagnose_evac_model(
  hazard_zone = result$hazard_zone,
  roads = result$roads,
  dem = result$dem,
  target_crs = target_crs,
  escape_zone = result$escape_zone,
  origins = result$road_points,
  destinations = result$escape_points,
  check_reachability = FALSE
)

diagnostic_summary <- data.frame(
  check = c(
    "Errors", "Warnings", "Informational checks", "Road features",
    "Sampled origins", "Candidate safety exits", "DEM resolution (m)"
  ),
  result = c(
    diagnostics$summary$n_errors,
    diagnostics$summary$n_warnings,
    diagnostics$summary$n_info,
    diagnostics$summary$n_roads,
    diagnostics$summary$n_origins,
    diagnostics$summary$n_destinations,
    paste(
      format(round(diagnostics$summary$dem_resolution_x, 2), nsmall = 2),
      format(round(diagnostics$summary$dem_resolution_y, 2), nsmall = 2),
      sep = " x "
    )
  ),
  stringsAsFactors = FALSE
)

output_objects <- data.frame(
  object = c(
    "hazard_zone",
    "escape_points",
    "road_points",
    "distance_points",
    "evac_polygons / time_grid"
  ),
  purpose = c(
    "Land-only area used for evacuation origins and mapped output.",
    "Candidate safety exits identified at the selected escape boundary.",
    "Sampled road-based origins used for least-cost calculations.",
    "Modeled distance to safety for sampled origins and zero-distance exits.",
    "Polygonized modeled distance and time surface for map output."
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(
  input_summary,
  file.path(data_dir, "pkgdown-example-input-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  time_summary,
  file.path(data_dir, "pkgdown-example-time-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  scenario_summary,
  file.path(data_dir, "pkgdown-example-scenario-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  output_objects,
  file.path(data_dir, "pkgdown-example-output-objects.csv"),
  row.names = FALSE
)
utils::write.csv(
  diagnostic_summary,
  file.path(data_dir, "pkgdown-example-diagnostic-summary.csv"),
  row.names = FALSE
)

local({
  png(
    file.path(figure_dir, "pkgdown-example-inputs.png"),
    width = 1500,
    height = 850,
    res = 180
  )
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    dev.off()
  }, add = TRUE)

  par(mar = c(3, 3, 3, 5), mgp = c(1.8, 0.6, 0), las = 1, bg = "white")
  plot(dem, ext = focus_extent,
       col = grDevices::gray.colors(24, start = 0.96, end = 0.55), axes = FALSE,
       main = "Example inputs and candidate safety exits", plg = FALSE)
  plot(hazard_zone, add = TRUE, col = "#b66a2e99", border = NA)
  plot(roads, add = TRUE, col = "#2f3433", lwd = 0.55)
  plot(result$escape_points, add = TRUE, pch = 21, bg = "#a94b4d", col = "white", cex = 0.65)
  legend(
    "right",
    legend = c("Hazard zone", "Roads", "Candidate safety exits"),
    pch = c(15, NA, 21),
    pt.bg = c("#b66a2e", NA, "#a94b4d"),
    col = c("#b66a2e", "#2f3433", "white"),
    lty = c(NA, 1, NA),
    lwd = c(NA, 1, NA),
    pt.cex = c(1, NA, 0.9),
    bty = "n",
    cex = 0.78,
    inset = 0.02
  )
})

local({
  png(
    file.path(figure_dir, "pkgdown-example-time.png"),
    width = 1500,
    height = 850,
    res = 180
  )
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    dev.off()
  }, add = TRUE)

  par(mar = c(3, 3, 3, 5), mgp = c(1.8, 0.6, 0), las = 1, bg = "white")
  plot(
    result$time_grid,
    "EvacTimeAvg",
    ext = focus_extent,
    col = hcl.colors(7, "YlOrRd", rev = TRUE),
    border = NA,
    axes = FALSE,
    main = "Modeled evacuation time to safety",
    plg = list(title = "Minutes", cex = 0.78, title.cex = 0.84)
  )
  plot(result$roads, add = TRUE, col = "#2f343380", lwd = 0.4)
  plot(result$escape_points, add = TRUE, pch = 21, bg = "#a94b4d", col = "white", cex = 0.6)
})

local({
  png(
    file.path(figure_dir, "pkgdown-example-scenarios.png"),
    width = 1500,
    height = 750,
    res = 180
  )
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    dev.off()
  }, add = TRUE)

  metrics <- rbind(
    median = scenario_summary$median_evac_time,
    mean = scenario_summary$mean_evac_time,
    maximum = scenario_summary$max_evac_time
  )
  par(mar = c(7, 4, 3, 1), mgp = c(2.2, 0.7, 0), las = 1, bg = "white")
  barplot(
    metrics,
    beside = TRUE,
    col = c("#465a5a", "#b66a2e", "#a94b4d"),
    border = NA,
    names.arg = gsub("_", "\n", scenario_summary$scenario),
    ylab = "Modeled time (minutes)",
    main = "Scenario sensitivity in modeled evacuation time"
  )
  legend(
    "topleft",
    legend = c("Median", "Mean", "Maximum"),
    fill = c("#465a5a", "#b66a2e", "#a94b4d"),
    border = NA,
    bty = "n",
    cex = 0.82
  )
})

if (!is.null(bottlenecks) && !is.null(bottlenecks$high_density_polygons) &&
    nrow(bottlenecks$high_density_polygons) > 0L) {
  local({
    png(
      file.path(figure_dir, "pkgdown-example-corridors.png"),
      width = 1500,
      height = 850,
      res = 180
    )
    oldpar <- par(no.readonly = TRUE)
    on.exit({
      par(oldpar)
      dev.off()
    }, add = TRUE)

    par(mar = c(3, 3, 3, 5), mgp = c(1.8, 0.6, 0), las = 1, bg = "white")
    plot(dem, ext = focus_extent,
         col = grDevices::gray.colors(24, start = 0.96, end = 0.55), axes = FALSE,
         main = "Modeled high-use corridors")
    plot(hazard_zone, add = TRUE, col = "#f1f3f266", border = NA)
    plot(roads, add = TRUE, col = "#2f343366", lwd = 0.35)
    plot(terra::vect(result$routes), add = TRUE, col = "#465a5a55", lwd = 0.45)
    plot(bottlenecks$high_density_polygons, add = TRUE, col = "#b66a2eAA", border = "#b66a2e")
    plot(result$escape_points, add = TRUE, pch = 21, bg = "#a94b4d", col = "white", cex = 0.55)
    legend(
      "right",
      legend = c("Selected high-density cells", "Modeled routes", "Candidate safety exits"),
      pch = c(15, NA, 21),
      pt.bg = c("#b66a2e", NA, "#a94b4d"),
      col = c("#b66a2e", "#465a5a", "white"),
      lty = c(NA, 1, NA),
      lwd = c(NA, 1, NA),
      pt.cex = c(1, NA, 0.9),
      bty = "n",
      cex = 0.75,
      inset = 0.02
    )
  })
}
