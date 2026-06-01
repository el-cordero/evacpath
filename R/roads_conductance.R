#' Create a road-constrained analysis mask
#'
#' Buffers the road network and candidate escape points, combines those buffered
#' areas, and dissolves the result. The mask is used to constrain least-cost
#' movement to the road/pathway network while allowing access around escape
#' locations.
#'
#' @param roads Road/pathway network.
#' @param escape_points Candidate escape/safety points.
#' @param road_buffer_m Road buffer distance in map units, typically meters.
#' @param escape_buffer_m Escape-point buffer distance in map units, typically meters.
#' @param return_components Logical. If `TRUE`, return a list with the mask and
#'   component buffers.
#' @return A dissolved road mask `SpatVector`, or a list when `return_components = TRUE`.
#' @examples
#' roads <- terra::vect(matrix(c(0, 1, 4, 1), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' escape <- terra::vect(data.frame(x = 4, y = 1), geom = c("x", "y"), crs = "EPSG:3857")
#' make_road_mask(roads, escape, road_buffer_m = 0.1, escape_buffer_m = 0.2)
#' @export
make_road_mask <- function(
  roads,
  escape_points,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  return_components = FALSE
) {
  roads <- read_spatial(roads)
  escape_points <- read_spatial(escape_points)

  roads_buffer <- terra::buffer(roads, road_buffer_m)
  roads_buffer <- .safe_aggregate(roads_buffer)

  escape_buffer <- terra::buffer(escape_points, escape_buffer_m)
  escape_buffer <- .safe_aggregate(escape_buffer)

  mask <- .combine_vectors(roads_buffer, escape_buffer)
  mask <- .safe_aggregate(mask)

  if (isTRUE(return_components)) {
    return(list(
      mask = mask,
      roads_buffer = roads_buffer,
      escape_buffer = escape_buffer
    ))
  }

  mask
}

#' Create road-based origin points inside the evacuation zone
#'
#' Intersects an evacuation grid with a buffered road network and converts the
#' resulting road-crossing cell geometry to points.
#'
#' @param evac_grid Polygon grid from `make_evac_grid()`.
#' @param roads_buffer Buffered road/pathway network.
#' @param hazard_zone Optional hazard-zone polygon used to crop candidate
#'   origins after intersecting the grid with the road buffer.
#' @param max_origins Optional maximum number of origin points to retain. Useful
#'   for large regions or exploratory runs.
#' @param seed Random seed used when `max_origins` is supplied.
#' @return A point `SpatVector` of road-based evacuation origins.
#' @examples
#' r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
#'   vals = 1, crs = "EPSG:3857")
#' grid <- make_evac_grid(terra::as.polygons(r, dissolve = TRUE), resolution = 1)
#' roads <- terra::vect(matrix(c(0, 2, 4, 2), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' roads_buffer <- terra::buffer(roads, 0.2)
#' make_road_origins(grid, roads_buffer, hazard_zone = terra::as.polygons(r, dissolve = TRUE),
#'   max_origins = 3, seed = 1)
#' @export
make_road_origins <- function(
    evac_grid,
    roads_buffer,
    hazard_zone = NULL,
    max_origins = NULL,
    seed = NULL
) {
  if (!inherits(evac_grid, "SpatVector")) {
    stop("`evac_grid` must be a terra SpatVector.", call. = FALSE)
  }
  
  if (!inherits(roads_buffer, "SpatVector")) {
    stop("`roads_buffer` must be a terra SpatVector.", call. = FALSE)
  }

  if (!is.null(hazard_zone) && !inherits(hazard_zone, "SpatVector")) {
    stop("`hazard_zone` must be a terra SpatVector.", call. = FALSE)
  }

  candidate_area <- terra::intersect(evac_grid, roads_buffer)
  
  if (!is.null(hazard_zone)) {
    candidate_area <- terra::intersect(candidate_area, hazard_zone)
  }
  
  origins <- terra::centroids(candidate_area, inside = TRUE)
  
  if (!is.null(hazard_zone)) {
    origins <- terra::intersect(origins, hazard_zone)
  }
  
  if (!is.null(max_origins) && max_origins < nrow(origins)) {
    if (!is.null(seed)) set.seed(seed)
    origins <- origins[sort(sample.int(nrow(origins), max_origins)), ]
  }
  
  origins
}

#' Create a slope-based conductance surface
#'
#' Masks a DEM to an optional road/pathway mask and creates a slope conductance
#' surface using `leastcostpath`.
#'
#' @param dem Elevation raster.
#' @param road_mask Optional road/pathway mask.
#' @param resolution Optional target DEM resolution before conductance creation.
#' @param method Conductance method. Currently only `"slope"` is implemented.
#' @param lcp_cost_function Character string or function passed to
#'   [leastcostpath::create_slope_cs()].
#' @param lcp_neighbours Neighbourhood passed to
#'   [leastcostpath::create_slope_cs()]. Use `4`, `8`, `16`, `32`, `48`, or a
#'   custom matrix accepted by `leastcostpath`.
#' @param lcp_crit_slope Numeric critical slope passed to
#'   [leastcostpath::create_slope_cs()].
#' @param lcp_max_slope Optional numeric maximum slope passed to
#'   [leastcostpath::create_slope_cs()].
#' @param ... Additional named arguments passed to
#'   [leastcostpath::create_slope_cs()], such as `exaggeration`.
#' @return A `leastcostpath` conductance surface object.
#' @examples
#' dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
#'   vals = 1, crs = "EPSG:3857")
#' make_conductance_surface(dem, lcp_neighbours = 8)
#' @export
make_conductance_surface <- function(
  dem,
  road_mask = NULL,
  resolution = NULL,
  method = "slope",
  lcp_cost_function = "tobler",
  lcp_neighbours = 16,
  lcp_crit_slope = 12,
  lcp_max_slope = NULL,
  ...
) {
  if (!is.character(method) || length(method) != 1L || is.na(method) || method != "slope") {
    stop("`method` must be \"slope\".", call. = FALSE)
  }
  method <- match.arg(method, choices = c("slope"))
  .validate_lcp_settings(
    lcp_cost_function = lcp_cost_function,
    lcp_neighbours = lcp_neighbours,
    lcp_crit_slope = lcp_crit_slope,
    lcp_max_slope = lcp_max_slope
  )

  dem <- read_spatial(dem)

  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` must be a SpatRaster or raster file path.", call. = FALSE)
  }

  if (!is.null(resolution)) {
    template <- terra::rast(ext = terra::ext(dem), crs = terra::crs(dem), resolution = resolution)
    dem <- terra::resample(dem, template)
  }

  if (!is.null(road_mask)) {
    road_mask <- read_spatial(road_mask)
    dem <- terra::mask(dem, road_mask)
  }

  extra_args <- list(...)
  if (length(extra_args) > 0L && (is.null(names(extra_args)) || any(names(extra_args) == ""))) {
    stop("Additional leastcostpath arguments passed through `...` must be named.", call. = FALSE)
  }

  explicit_names <- c("x", "cost_function", "neighbours", "crit_slope", "max_slope")
  extra_args <- extra_args[setdiff(names(extra_args), explicit_names)]

  do.call(
    leastcostpath::create_slope_cs,
    c(
      list(
        x = dem,
        cost_function = lcp_cost_function,
        neighbours = lcp_neighbours,
        crit_slope = lcp_crit_slope,
        max_slope = lcp_max_slope
      ),
      extra_args
    )
  )
}
