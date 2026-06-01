# Internal planning helpers -------------------------------------------------

merge_scenario_args <- function(shared_args, scenario_args) {
  if (!is.list(shared_args) || !is.list(scenario_args)) {
    stop("Shared and scenario-specific arguments must be lists.", call. = FALSE)
  }
  if (length(scenario_args) > 0L &&
      (is.null(names(scenario_args)) || any(names(scenario_args) == ""))) {
    stop("Each scenario override must be a named list.", call. = FALSE)
  }

  shared_args[names(scenario_args)] <- scenario_args
  shared_args
}

safe_metric <- function(expr, default = NA_real_) {
  tryCatch(expr, error = function(e) default)
}

extract_distance_points <- function(x) {
  if (inherits(x, c("SpatVector", "sf"))) {
    return(x)
  }
  if (is.list(x) && !is.null(x$distance_points)) {
    return(x$distance_points)
  }
  NULL
}

extract_time_polygons <- function(x) {
  if (!is.list(x)) {
    return(NULL)
  }
  if (!is.null(x$time_grid)) {
    return(x$time_grid)
  }
  x$evac_polygons
}

extract_routes <- function(x) {
  if (inherits(x, c("SpatVector", "sf"))) {
    return(x)
  }
  if (is.list(x) && !is.null(x$routes)) {
    return(x$routes)
  }
  NULL
}

check_projected_crs <- function(x) {
  if (is.null(x)) {
    return(FALSE)
  }
  if (inherits(x, "sf")) {
    crs <- sf::st_crs(x)
    return(!is.na(crs) && !sf::st_is_longlat(x))
  }
  if (inherits(x, c("SpatRaster", "SpatVector"))) {
    crs <- terra::crs(x)
    return(!is.na(crs) && nzchar(crs) && !terra::is.lonlat(x))
  }
  FALSE
}

.spatial_nrow <- function(x) {
  if (is.null(x)) {
    return(NA_integer_)
  }
  safe_metric(nrow(x), default = NA_integer_)
}

.as_sf_layer <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, "sf")) {
    return(x)
  }
  if (inherits(x, "SpatVector")) {
    return(sf::st_as_sf(x))
  }
  NULL
}

.tag_spatial_layer <- function(x, scenario, scenario_id_col) {
  if (is.null(x)) {
    return(NULL)
  }
  x[[scenario_id_col]] <- rep(scenario, nrow(x))
  x
}

.tag_evac_result <- function(result, scenario, scenario_id_col) {
  if (!is.list(result) || !is.null(result$error)) {
    return(result)
  }

  for (name in c("distance_points", "evac_polygons", "time_grid", "routes")) {
    if (!is.null(result[[name]])) {
      result[[name]] <- .tag_spatial_layer(result[[name]], scenario, scenario_id_col)
    }
  }
  result
}

.bind_sf_layers <- function(xs) {
  xs <- xs[!vapply(xs, is.null, logical(1))]
  xs <- lapply(xs, .as_sf_layer)
  xs <- xs[!vapply(xs, is.null, logical(1))]
  if (length(xs) == 0L) {
    return(NULL)
  }
  do.call(rbind, xs)
}

.format_lcp_value <- function(x) {
  if (is.null(x)) {
    return(NA_character_)
  }
  if (is.function(x)) {
    return("<function>")
  }
  if (is.matrix(x)) {
    return("<custom matrix>")
  }
  paste(x, collapse = ", ")
}

extract_evac_summary <- function(result, scenario = NULL) {
  parameters <- if (is.list(result)) result$parameters else NULL
  distance_points <- extract_distance_points(result)
  time_polygons <- extract_time_polygons(result)
  walking_speed_mps <- safe_metric(parameters$walking_speed_mps)
  if (length(walking_speed_mps) != 1L || !is.numeric(walking_speed_mps)) {
    walking_speed_mps <- NA_real_
  }

  times <- numeric()
  if (!is.null(distance_points) && "distance" %in% names(distance_points) &&
      is.numeric(walking_speed_mps) && length(walking_speed_mps) == 1L &&
      is.finite(walking_speed_mps) && walking_speed_mps > 0) {
    values <- terra::values(distance_points)
    if ("type" %in% names(values)) {
      values <- values[values$type != "escape", , drop = FALSE]
    }
    times <- calc_evac_time(values$distance, walking_speed_mps = walking_speed_mps)
  } else if (!is.null(time_polygons) && "EvacTimeAvg" %in% names(time_polygons)) {
    times <- as.numeric(terra::values(time_polygons)$EvacTimeAvg)
  }

  times <- times[is.finite(times)]
  n_origins <- .spatial_nrow(if (is.list(result)) result$road_points else NULL)
  n_destinations <- .spatial_nrow(if (is.list(result)) result$escape_points else NULL)

  data.frame(
    scenario = if (is.null(scenario)) NA_character_ else scenario,
    n_origins = n_origins,
    n_destinations = n_destinations,
    min_evac_time = if (length(times) > 0L) min(times) else NA_real_,
    median_evac_time = if (length(times) > 0L) stats::median(times) else NA_real_,
    mean_evac_time = if (length(times) > 0L) mean(times) else NA_real_,
    max_evac_time = if (length(times) > 0L) max(times) else NA_real_,
    pct_over_10_min = if (length(times) > 0L) mean(times > 10) * 100 else NA_real_,
    pct_over_15_min = if (length(times) > 0L) mean(times > 15) * 100 else NA_real_,
    pct_over_20_min = if (length(times) > 0L) mean(times > 20) * 100 else NA_real_,
    pct_over_30_min = if (length(times) > 0L) mean(times > 30) * 100 else NA_real_,
    lcp_cost_function = .format_lcp_value(parameters$lcp_cost_function),
    lcp_neighbours = .format_lcp_value(parameters$lcp_neighbours),
    walking_speed_mps = walking_speed_mps,
    stringsAsFactors = FALSE
  )
}

#' Compare evacuation scenarios
#'
#' Runs [run_evacpath()] repeatedly across named scenario overrides and returns
#' scenario summaries with combined spatial outputs when those layers are
#' available.
#'
#' @param scenarios Named list. Each element is a named list of arguments that
#'   override shared arguments passed through `...`.
#' @param ... Shared arguments passed to [run_evacpath()].
#' @param scenario_id_col Name of the scenario identifier column added to
#'   combined spatial outputs.
#' @param keep_routes Logical. Retain selected least-cost routes in each scenario
#'   result. Use `TRUE` when route-density analysis is needed.
#' @param quiet Logical. If `TRUE`, suppress warnings when a scenario fails or
#'   summary metrics are unavailable.
#' @return An `evac_scenario_comparison` list with `results`, `summary`,
#'   `distance_points`, `time_polygons`, and `metadata`.
#' @examples
#' dem <- terra::rast(nrows = 7, ncols = 7, xmin = 0, xmax = 7, ymin = 0, ymax = 7,
#'   vals = 1, crs = "EPSG:3857")
#' hazard <- terra::as.polygons(terra::crop(dem, terra::ext(1, 6, 1, 6)), dissolve = TRUE)
#' roads <- terra::vect(matrix(c(0, 3.5, 7, 3.5), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' comparison <- compare_evac_scenarios(
#'   scenarios = list(baseline = list(), slower = list(walking_speed_mps = 0.9)),
#'   hazard_zone = hazard, roads = roads, dem = dem, grid_resolution = 1,
#'   road_buffer_m = 0.2, escape_buffer_m = 0.3, final_road_buffer_m = 0.2,
#'   max_origins = 1, max_destinations = 2, seed = 1
#' )
#' comparison$summary
#' @export
compare_evac_scenarios <- function(
  scenarios,
  ...,
  scenario_id_col = "scenario",
  keep_routes = FALSE,
  quiet = FALSE
) {
  if (!is.list(scenarios) || length(scenarios) == 0L ||
      is.null(names(scenarios)) || any(names(scenarios) == "") ||
      anyDuplicated(names(scenarios))) {
    stop("`scenarios` must be a non-empty named list with unique scenario names.", call. = FALSE)
  }
  if (!is.character(scenario_id_col) || length(scenario_id_col) != 1L ||
      is.na(scenario_id_col) || !nzchar(scenario_id_col)) {
    stop("`scenario_id_col` must be a single non-empty character string.", call. = FALSE)
  }

  shared_args <- list(...)
  scenario_results <- vector("list", length(scenarios))
  names(scenario_results) <- names(scenarios)
  effective_args <- vector("list", length(scenarios))
  names(effective_args) <- names(scenarios)
  summaries <- vector("list", length(scenarios))

  for (i in seq_along(scenarios)) {
    scenario <- names(scenarios)[i]
    args <- merge_scenario_args(shared_args, scenarios[[i]])
    args$keep_routes <- isTRUE(keep_routes) || isTRUE(args$keep_routes)
    effective_args[[i]] <- args

    result <- tryCatch(
      do.call(run_evacpath, args),
      error = function(e) {
        if (!isTRUE(quiet)) {
          warning("Scenario `", scenario, "` failed: ", conditionMessage(e), call. = FALSE)
        }
        list(error = conditionMessage(e), parameters = args)
      }
    )

    result <- .tag_evac_result(result, scenario, scenario_id_col)
    scenario_results[[i]] <- result
    summaries[[i]] <- extract_evac_summary(result, scenario = scenario)

    time_metrics <- summaries[[i]][c(
      "min_evac_time", "median_evac_time", "mean_evac_time", "max_evac_time"
    )]
    if (!isTRUE(quiet) && all(is.na(time_metrics))) {
      warning("Scenario `", scenario, "` did not produce evacuation-time metrics.", call. = FALSE)
    }
  }

  out <- list(
    results = scenario_results,
    summary = do.call(rbind, summaries),
    distance_points = .bind_sf_layers(lapply(scenario_results, extract_distance_points)),
    time_polygons = .bind_sf_layers(lapply(scenario_results, extract_time_polygons)),
    metadata = list(
      scenario_id_col = scenario_id_col,
      shared_args = shared_args,
      scenario_args = scenarios,
      effective_args = effective_args,
      keep_routes = keep_routes
    )
  )
  rownames(out$summary) <- NULL
  class(out) <- c("evac_scenario_comparison", "list")
  out
}

#' @export
print.evac_scenario_comparison <- function(x, ...) {
  cat("<evac_scenario_comparison>\n")
  cat("Scenarios: ", length(x$results), "\n", sep = "")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

#' Map modeled evacuation bottlenecks
#'
#' Creates a route-density raster and identifies high-use modeled evacuation
#' corridors from supplied least-cost paths or an [run_evacpath()] result created
#' with `keep_routes = TRUE`.
#'
#' @param routes An `sf` or `SpatVector` line layer of modeled routes.
#' @param evac_result Optional output from [run_evacpath()] containing retained
#'   routes.
#' @param template Optional `SpatRaster` defining the density grid. When omitted,
#'   the function attempts to infer a template from `evac_result`.
#' @param quantile_threshold Numeric value between `0` and `1`. Used to select
#'   high-density route cells when `min_count` is `NULL`.
#' @param min_count Optional numeric minimum density count. When supplied, this
#'   takes precedence over `quantile_threshold`.
#' @param rescale Logical passed to [leastcostpath::create_lcp_density()].
#' @param return_polygons Logical. Convert high-density raster cells to polygons.
#' @param ... Reserved for future extensions.
#' @return An `evac_bottleneck` list with density rasters, optional polygons,
#'   threshold value, and summary.
#' @examples
#' template <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
#'   vals = 1, crs = "EPSG:3857")
#' routes <- sf::st_sf(
#'   route = c("a", "b"),
#'   geometry = sf::st_sfc(
#'     sf::st_linestring(matrix(c(0.5, 0.5, 4.5, 4.5), ncol = 2, byrow = TRUE)),
#'     sf::st_linestring(matrix(c(0.5, 4.5, 4.5, 0.5), ncol = 2, byrow = TRUE)),
#'     crs = 3857
#'   )
#' )
#' map_evac_bottlenecks(routes = routes, template = template)
#' @export
map_evac_bottlenecks <- function(
  routes = NULL,
  evac_result = NULL,
  template = NULL,
  quantile_threshold = 0.9,
  min_count = NULL,
  rescale = FALSE,
  return_polygons = TRUE,
  ...
) {
  if (is.null(routes)) {
    routes <- extract_routes(evac_result)
  }
  if (is.null(routes)) {
    stop("Supply `routes` or an `evac_result` created with `keep_routes = TRUE`.", call. = FALSE)
  }
  if (!inherits(routes, c("sf", "SpatVector"))) {
    stop("`routes` must be an sf or terra SpatVector line layer.", call. = FALSE)
  }
  if (nrow(routes) == 0L) {
    stop("`routes` is empty.", call. = FALSE)
  }

  route_types <- if (inherits(routes, "sf")) {
    as.character(sf::st_geometry_type(routes, by_geometry = TRUE))
  } else {
    terra::geomtype(routes)
  }
  if (!all(grepl("LINE", toupper(route_types)))) {
    stop("`routes` must contain only LINESTRING or MULTILINESTRING geometries.", call. = FALSE)
  }

  if (is.null(template) && is.list(evac_result) && !is.null(evac_result$conductance)) {
    template <- leastcostpath::rasterise(evac_result$conductance)
  }
  if (is.null(template) && is.list(evac_result) && !is.null(evac_result$dem)) {
    template <- evac_result$dem
  }
  if (is.null(template)) {
    stop("Supply a `template` SpatRaster or an `evac_result` with a raster template.", call. = FALSE)
  }

  template <- read_spatial(template)
  if (!inherits(template, "SpatRaster")) {
    stop("`template` must be a terra SpatRaster.", call. = FALSE)
  }
  if (!is.numeric(quantile_threshold) || length(quantile_threshold) != 1L ||
      is.na(quantile_threshold) || quantile_threshold < 0 || quantile_threshold > 1) {
    stop("`quantile_threshold` must be a single numeric value between 0 and 1.", call. = FALSE)
  }
  if (!is.null(min_count) &&
      (!is.numeric(min_count) || length(min_count) != 1L ||
        is.na(min_count) || !is.finite(min_count) || min_count <= 0)) {
    stop("`min_count` must be NULL or a single positive numeric value.", call. = FALSE)
  }

  density <- leastcostpath::create_lcp_density(x = template, lcps = routes, rescale = rescale)
  density_values <- as.numeric(terra::values(density)[, 1])
  route_values <- density_values[is.finite(density_values) & density_values > 0]
  if (length(route_values) == 0L) {
    stop("No route density cells were created from `routes` and `template`.", call. = FALSE)
  }

  threshold_value <- if (!is.null(min_count)) {
    min_count
  } else {
    as.numeric(stats::quantile(route_values, probs = quantile_threshold, names = FALSE))
  }
  high_density <- terra::ifel(density >= threshold_value & density > 0, density, NA)
  high_values <- as.numeric(terra::values(high_density)[, 1])
  n_high <- sum(is.finite(high_values))

  high_polygons <- NULL
  if (isTRUE(return_polygons) && n_high > 0L) {
    high_polygons <- terra::as.polygons(high_density, dissolve = TRUE, na.rm = TRUE)
  }

  area_high_density_m2 <- if (check_projected_crs(template)) {
    n_high * prod(terra::res(template))
  } else {
    NA_real_
  }

  out <- list(
    density_raster = density,
    high_density_raster = high_density,
    high_density_polygons = high_polygons,
    threshold_value = threshold_value,
    summary = data.frame(
      n_routes = nrow(routes),
      max_density = max(route_values),
      threshold_value = threshold_value,
      area_high_density_m2 = area_high_density_m2,
      percent_of_route_area_high_density = n_high / length(route_values) * 100
    )
  )
  class(out) <- c("evac_bottleneck", "list")
  out
}

#' @export
print.evac_bottleneck <- function(x, ...) {
  cat("<evac_bottleneck>\n")
  print(x$summary, row.names = FALSE)
  invisible(x)
}
