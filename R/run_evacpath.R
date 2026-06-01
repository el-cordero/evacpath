#' Run the full evacuation-path modeling workflow
#'
#' This high-level wrapper runs the core `evacpath` pipeline: read/project inputs,
#' create an evacuation grid, identify escape/safety points, build a road mask,
#' create a slope-based conductance surface, calculate minimum least-cost distance
#' to safety, and create evacuation-time polygons.
#'
#' For tsunami applications, `hazard_zone` and `escape_zone` should often be
#' different. Use a land-only `hazard_zone` for origins and output mapping, but
#' use a water-combined `escape_zone` for escape-point detection so the coastline
#' is not treated as an artificial safety boundary. The helper
#' `prepare_tsunami_zones()` creates both objects.
#'
#' @param hazard_zone Hazard/inundation zone as `SpatRaster`, `SpatVector`, or path.
#'   This should usually be the land-only area where evacuation origins and final
#'   output surfaces are mapped.
#' @param roads Road/pathway network as `SpatVector` or path.
#' @param dem Elevation raster as `SpatRaster` or path.
#' @param target_crs Optional projected CRS in meters, for example `"EPSG:32748"`.
#' @param region_name Optional region name stored in output polygons.
#' @param escape_zone Optional boundary zone used only to identify escape/safety
#'   points. For tsunami workflows, pass the land-inundation-plus-water zone from
#'   `prepare_tsunami_zones()` here. If `NULL`, `hazard_zone` is used.
#' @param roads_for_escape Optional road/pathway layer used only for escape-point
#'   detection. If `NULL`, `roads` is used. This is useful when the full road
#'   dataset extends beyond the reliable hazard-zone study extent.
#' @param escape_roads_inset_x_m Optional x-direction inset applied to
#'   `roads_for_escape` before escape-point detection. This prevents roads from
#'   intersecting artificial study-area extent boundaries.
#' @param escape_roads_inset_y_m Optional y-direction inset applied to
#'   `roads_for_escape` before escape-point detection.
#' @param road_aware_escape_zone Logical. If `TRUE`, buffered `roads_for_escape`
#'   are combined with `escape_zone` before escape points are generated. This
#'   preserves bridge, causeway, and walkway corridors over water that can be lost
#'   when the tsunami layer is split into land and water masks.
#' @param escape_zone_road_buffer_m Road buffer used when `road_aware_escape_zone = TRUE`.
#' @param escape_zone_crop_buffer_m Additional buffer used when `road_aware_escape_zone = TRUE`.
#' @param study_area Optional local study area for limiting escape-point search.
#' @param road_exclude Optional list passed to `clean_roads()`.
#' @param grid_resolution Evacuation-grid resolution. If `NULL`, calculated from
#'   `terra::res(dem) * grid_resolution_factor`.
#' @param grid_resolution_factor Multiplier applied to DEM resolution when
#'   `grid_resolution = NULL`.
#' @param road_buffer_m Road buffer distance.
#' @param escape_buffer_m Escape-point buffer distance.
#' @param final_road_buffer_m Output clipping buffer around roads.
#' @param region_buffer_m Buffer around `study_area` used when finding escape points.
#' @param dem_resolution Optional DEM resolution used before conductance creation.
#' @param max_origins Optional maximum number of road origin points.
#' @param max_destinations Optional maximum number of escape/safety destination points.
#'   This is useful for quick tests in regions where roads intersect the hazard
#'   boundary many times.
#' @param seed Random seed used when `max_origins` or `max_destinations` is supplied.
#' @param walking_speed_mps Walking speed in meters per second.
#'   This controls conversion of modeled route distances into evacuation times.
#'   It does not change route geometry.
#' @param lcp_cost_function Character string or function passed to
#'   [leastcostpath::create_slope_cs()]. This changes conductance and may change
#'   route geometry.
#' @param lcp_neighbours Neighbourhood passed to
#'   [leastcostpath::create_slope_cs()]. Use `4`, `8`, `16`, `32`, `48`, or a
#'   custom matrix accepted by `leastcostpath`.
#' @param lcp_crit_slope Numeric critical slope passed to
#'   [leastcostpath::create_slope_cs()].
#' @param lcp_max_slope Optional numeric maximum traversable slope passed to
#'   [leastcostpath::create_slope_cs()].
#' @param lcp_args Named list of additional arguments passed to
#'   [leastcostpath::create_slope_cs()], such as `exaggeration`. Explicit
#'   `lcp_*` arguments take precedence over duplicate entries in this list.
#' @param clip_mode Output clipping mode. The default `"hazard"` creates a
#'   continuous time-grid polygon surface clipped to the land-only hazard zone.
#'   Use `"road_hazard"` for the older road-buffer-limited output,
#'   `"hazard_plus_roads"` to retain both, or `"none"` for unclipped Voronoi polygons.
#' @param progress Logical. Print progress while running least-cost paths.
#' @param progress_every Integer. Print progress every `n` origins when `progress = TRUE`.
#' @param lcp_check_locations Logical passed to `leastcostpath::create_lcp()`.
#'   Default is `FALSE` for speed after projection/cropping checks.
#' @param keep_routes Logical. If `TRUE`, retain the selected least-cost route
#'   for each reachable origin in `result$routes`. The default is `FALSE` to
#'   avoid the additional memory cost.
#' @return An `evacpath_result` list containing spatial outputs and parameters.
#' @examples
#' dem <- terra::rast(nrows = 7, ncols = 7, xmin = 0, xmax = 7, ymin = 0, ymax = 7,
#'   vals = 1, crs = "EPSG:3857")
#' hazard_raster <- terra::crop(dem, terra::ext(1, 6, 1, 6))
#' hazard <- terra::as.polygons(hazard_raster, dissolve = TRUE)
#' roads <- terra::vect(matrix(c(0, 3.5, 7, 3.5), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' result <- run_evacpath(
#'   hazard_zone = hazard,
#'   roads = roads,
#'   dem = dem,
#'   grid_resolution = 1,
#'   road_buffer_m = 0.2,
#'   escape_buffer_m = 0.3,
#'   final_road_buffer_m = 0.2,
#'   max_origins = 2,
#'   max_destinations = 2,
#'   seed = 1
#' )
#' result
#' @export
run_evacpath <- function(
  hazard_zone,
  roads,
  dem,
  target_crs = NULL,
  region_name = NULL,
  escape_zone = NULL,
  roads_for_escape = NULL,
  escape_roads_inset_x_m = 0,
  escape_roads_inset_y_m = 0,
  road_aware_escape_zone = FALSE,
  escape_zone_road_buffer_m = NULL,
  escape_zone_crop_buffer_m = NULL,
  study_area = NULL,
  road_exclude = NULL,
  grid_resolution = NULL,
  grid_resolution_factor = 5,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  final_road_buffer_m = 3,
  region_buffer_m = 5000,
  dem_resolution = NULL,
  max_origins = NULL,
  max_destinations = NULL,
  seed = 23401,
  walking_speed_mps = 1.22,
  lcp_cost_function = "tobler",
  lcp_neighbours = 16,
  lcp_crit_slope = 12,
  lcp_max_slope = NULL,
  lcp_args = list(),
  clip_mode = c("hazard", "road_hazard", "hazard_plus_roads", "none"),
  progress = FALSE,
  progress_every = 1L,
  lcp_check_locations = FALSE,
  keep_routes = FALSE
) {
  clip_mode <- match.arg(clip_mode)
  .validate_lcp_settings(
    lcp_cost_function = lcp_cost_function,
    lcp_neighbours = lcp_neighbours,
    lcp_crit_slope = lcp_crit_slope,
    lcp_max_slope = lcp_max_slope
  )

  if (!is.list(lcp_args)) {
    stop("`lcp_args` must be a named list.", call. = FALSE)
  }
  if (length(lcp_args) > 0L && (is.null(names(lcp_args)) || any(names(lcp_args) == ""))) {
    stop("`lcp_args` must be a named list.", call. = FALSE)
  }

  inputs <- prepare_evac_inputs(
    hazard_zone = hazard_zone,
    roads = roads,
    dem = dem,
    target_crs = target_crs,
    hazard_as_polygon = TRUE,
    dissolve_hazard = TRUE,
    road_exclude = road_exclude
  )

  hazard_zone <- inputs$hazard_zone
  roads <- inputs$roads
  dem <- inputs$dem

  if (is.null(escape_zone)) {
    escape_zone <- hazard_zone
  } else {
    escape_zone <- read_spatial(escape_zone)
    if (!is.null(target_crs)) {
      escape_zone <- .project_to(escape_zone, target_crs)
    }
    escape_zone <- .as_hazard_polygon(escape_zone, dissolve = TRUE)
  }

  if (is.null(roads_for_escape)) {
    roads_for_escape <- roads
  } else {
    roads_for_escape <- read_spatial(roads_for_escape)
    if (!inherits(roads_for_escape, "SpatVector")) {
      stop("`roads_for_escape` must be a SpatVector or vector file path.", call. = FALSE)
    }
    if (!is.null(target_crs)) {
      roads_for_escape <- .project_to(roads_for_escape, target_crs)
    }
  }

  if (isTRUE(escape_roads_inset_x_m > 0 || escape_roads_inset_y_m > 0)) {
    roads_for_escape <- crop_roads_to_inner_extent(
      roads = roads_for_escape,
      zone = escape_zone,
      inset_x_m = escape_roads_inset_x_m,
      inset_y_m = escape_roads_inset_y_m
    )
  }

  escape_boundary_zone <- escape_zone
  if (isTRUE(road_aware_escape_zone)) {
    if (is.null(escape_zone_road_buffer_m)) {
      escape_zone_road_buffer_m <- road_buffer_m
    }
    if (is.null(escape_zone_crop_buffer_m)) {
      escape_zone_crop_buffer_m <- final_road_buffer_m
    }

    escape_boundary_zone <- make_road_aware_escape_zone(
      escape_zone = escape_zone,
      roads = roads_for_escape,
      road_buffer_m = escape_zone_road_buffer_m,
      crop_buffer_m = escape_zone_crop_buffer_m,
      include_base_zone = TRUE
    )
  }

  if (!is.null(study_area)) {
    study_area <- read_spatial(study_area)
    if (!is.null(target_crs)) {
      study_area <- .project_to(study_area, target_crs)
    }
  }

  if (is.null(grid_resolution)) {
    grid_resolution <- terra::res(dem) * grid_resolution_factor
  }

  evac_grid <- make_evac_grid(hazard_zone, resolution = grid_resolution)

  escape_points <- find_escape_points(
    hazard_zone = escape_boundary_zone,
    roads = roads_for_escape,
    study_area = study_area,
    region_buffer_m = region_buffer_m
  )

  if (!is.null(max_destinations)) {
    nd <- nrow(escape_points)
    if (!is.na(nd) && max_destinations < nd) {
      set.seed(seed)
      escape_points <- escape_points[sort(sample.int(nd, max_destinations)), ]
      if (isTRUE(progress)) {
        message("Using ", nrow(escape_points), " sampled escape/safety destinations.")
      }
    }
  }

  if (isTRUE(progress)) {
    message("Escape/safety destinations: ", nrow(escape_points))
  }

  road_mask_parts <- make_road_mask(
    roads = roads,
    escape_points = escape_points,
    road_buffer_m = road_buffer_m,
    escape_buffer_m = escape_buffer_m,
    return_components = TRUE
  )

  explicit_lcp_names <- c(
    "lcp_cost_function", "lcp_neighbours", "lcp_crit_slope", "lcp_max_slope",
    "cost_function", "neighbours", "crit_slope", "max_slope", "x"
  )
  lcp_args <- lcp_args[setdiff(names(lcp_args), explicit_lcp_names)]

  conductance <- do.call(
    make_conductance_surface,
    c(
      list(
        dem = dem,
        road_mask = road_mask_parts$mask,
        resolution = dem_resolution,
        lcp_cost_function = lcp_cost_function,
        lcp_neighbours = lcp_neighbours,
        lcp_crit_slope = lcp_crit_slope,
        lcp_max_slope = lcp_max_slope
      ),
      lcp_args
    )
  )

  road_points <- make_road_origins(
    evac_grid = evac_grid,
    roads_buffer = road_mask_parts$roads_buffer,
    hazard_zone = hazard_zone,
    max_origins = max_origins,
    seed = seed
  )

  if (isTRUE(progress)) {
    message("Road origins: ", nrow(road_points))
  }

  distance_result <- calc_min_distance_to_safety(
    cs = conductance,
    origins = road_points,
    destinations = escape_points,
    progress = progress,
    progress_every = progress_every,
    check_locations = lcp_check_locations,
    return_routes = keep_routes
  )

  if (isTRUE(keep_routes)) {
    distance_points <- distance_result$distance_points
    routes <- distance_result$routes
    unreachable_origins <- distance_result$unreachable_origins
  } else {
    distance_points <- distance_result
    routes <- NULL
    unreachable_origins <- NULL
  }

  clip_area <- make_output_clip_area(
    hazard_zone = hazard_zone,
    roads_buffer = road_mask_parts$roads_buffer,
    final_road_buffer_m = final_road_buffer_m,
    clip_mode = clip_mode
  )

  evac_polygons <- make_evac_polygons(
    distance_points = distance_points,
    clip_area = clip_area,
    walking_speed_mps = walking_speed_mps,
    region_name = region_name
  )

  result <- list(
    region_name = region_name,
    target_crs = target_crs,
    parameters = list(
      grid_resolution = grid_resolution,
      grid_resolution_factor = grid_resolution_factor,
      road_buffer_m = road_buffer_m,
      escape_buffer_m = escape_buffer_m,
      escape_roads_inset_x_m = escape_roads_inset_x_m,
      escape_roads_inset_y_m = escape_roads_inset_y_m,
      road_aware_escape_zone = road_aware_escape_zone,
      escape_zone_road_buffer_m = escape_zone_road_buffer_m,
      escape_zone_crop_buffer_m = escape_zone_crop_buffer_m,
      final_road_buffer_m = final_road_buffer_m,
      region_buffer_m = region_buffer_m,
      dem_resolution = dem_resolution,
      max_origins = max_origins,
      max_destinations = max_destinations,
      seed = seed,
      walking_speed_mps = walking_speed_mps,
      lcp_cost_function = lcp_cost_function,
      lcp_neighbours = lcp_neighbours,
      lcp_crit_slope = lcp_crit_slope,
      lcp_max_slope = lcp_max_slope,
      lcp_args = lcp_args,
      clip_mode = clip_mode,
      progress_every = progress_every,
      lcp_check_locations = lcp_check_locations,
      keep_routes = keep_routes
    ),
    hazard_zone = hazard_zone,
    escape_zone = escape_zone,
    escape_boundary_zone = escape_boundary_zone,
    roads = roads,
    roads_for_escape = roads_for_escape,
    dem = dem,
    study_area = study_area,
    evac_grid = evac_grid,
    escape_points = escape_points,
    road_mask = road_mask_parts$mask,
    roads_buffer = road_mask_parts$roads_buffer,
    escape_buffer = road_mask_parts$escape_buffer,
    road_points = road_points,
    conductance = conductance,
    distance_points = distance_points,
    routes = routes,
    unreachable_origins = unreachable_origins,
    clip_area = clip_area,
    evac_polygons = evac_polygons,
    time_grid = evac_polygons
  )

  class(result) <- c("evacpath_result", class(result))
  result
}

#' Make an output clip area for evacuation polygons
#'
#' @param hazard_zone Hazard zone polygon.
#' @param roads_buffer Buffered roads.
#' @param final_road_buffer_m Additional road buffer for output clipping.
#' @param clip_mode One of `"hazard"`, `"road_hazard"`, `"hazard_plus_roads"`, or `"none"`.
#' @return A `SpatVector` clip area or `NULL`.
make_output_clip_area <- function(
  hazard_zone,
  roads_buffer,
  final_road_buffer_m = 3,
  clip_mode = c("hazard", "road_hazard", "hazard_plus_roads", "none")
) {
  clip_mode <- match.arg(clip_mode)

  if (clip_mode == "none") {
    return(NULL)
  }

  if (clip_mode == "hazard") {
    return(hazard_zone)
  }

  road_clip <- terra::buffer(roads_buffer, final_road_buffer_m)
  road_clip <- terra::crop(road_clip, hazard_zone)
  road_clip <- .safe_aggregate(road_clip)

  if (clip_mode == "road_hazard") {
    return(road_clip)
  }

  out <- .combine_vectors(road_clip, hazard_zone)
  .safe_aggregate(out)
}

#' @export
print.evacpath_result <- function(x, ...) {
  cat("<evacpath_result>\n")
  if (!is.null(x$region_name)) {
    cat("Region: ", x$region_name, "\n", sep = "")
  }
  if (!is.null(x$target_crs)) {
    cat("Target CRS: ", x$target_crs, "\n", sep = "")
  }
  cat("Outputs:\n")
  cat("  - hazard_zone (land-only output/origin zone)\n")
  cat("  - escape_zone (base escape zone)\n")
  cat("  - escape_boundary_zone (road-aware/inset-adjusted boundary used for escape points)\n")
  cat("  - roads_for_escape\n")
  cat("  - evac_grid\n")
  cat("  - escape_points\n")
  cat("  - road_points\n")
  cat("  - distance_points\n")
  if (!is.null(x$routes)) {
    cat("  - routes\n")
  }
  cat("  - evac_polygons / time_grid\n")
  invisible(x)
}
