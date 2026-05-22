#' Create an evacuation grid
#'
#' Creates polygon grid cells over a hazard/evacuation zone and masks the grid to
#' the zone. The resulting cells can be intersected with buffered roads to create
#' road-based origin points.
#'
#' @param hazard_zone Hazard/evacuation zone as `SpatVector`, `SpatRaster`, or file path.
#' @param resolution Grid cell resolution in map units. Use meters when data are
#'   in a projected CRS. Can be length 1 or 2.
#' @return A polygon `SpatVector` grid clipped/masked to the hazard zone.
#' @examples
#' r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
#'   vals = 1, crs = "EPSG:3857")
#' zone <- terra::as.polygons(r, dissolve = TRUE)
#' make_evac_grid(zone, resolution = 1)
#' @export
make_evac_grid <- function(hazard_zone, resolution) {
  hazard_zone <- read_spatial(hazard_zone)
  hazard_poly <- .as_hazard_polygon(hazard_zone, dissolve = TRUE)

  grid_r <- terra::rast(
    ext = terra::ext(hazard_poly),
    crs = terra::crs(hazard_poly),
    resolution = resolution
  )
  grid_p <- terra::as.polygons(grid_r)
  grid <- terra::mask(grid_p, hazard_poly)
  .stop_empty(grid, "Evacuation grid")
  grid
}

#' Create a broader analysis region around a study area
#'
#' Dissolves the full hazard zone, buffers a smaller study area, and crops the
#' full zone to that buffer. This is useful when escape/safety points outside a
#' municipality or local study area should still be considered.
#'
#' @param hazard_zone Full hazard/evacuation zone.
#' @param study_area Local study area.
#' @param buffer_m Buffer distance in map units, typically meters.
#' @return A polygon `SpatVector` for the broader analysis region.
#' @examples
#' r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
#'   vals = 1, crs = "EPSG:3857")
#' zone <- terra::as.polygons(r, dissolve = TRUE)
#' study <- terra::as.polygons(terra::crop(r, terra::ext(1, 3, 1, 3)), dissolve = TRUE)
#' make_region_area(zone, study, buffer_m = 1)
#' @export
make_region_area <- function(hazard_zone, study_area, buffer_m = 5000) {
  hazard_zone <- .as_hazard_polygon(read_spatial(hazard_zone), dissolve = TRUE)
  study_area <- .as_hazard_polygon(read_spatial(study_area), dissolve = TRUE)

  study_buffer <- terra::buffer(study_area, buffer_m)
  study_buffer <- .safe_aggregate(study_buffer)

  region <- terra::crop(hazard_zone, study_buffer)
  region <- tryCatch(terra::erase(region), error = function(e) region)
  .stop_empty(region, "Region area")
  region
}

#' Identify escape/safety points where roads cross the hazard-zone boundary
#'
#' Intersects a road/pathway network with the boundary of the hazard zone and
#' converts the intersection geometry to points. These points represent candidate
#' exits from the hazard zone.
#'
#' @param hazard_zone Hazard/evacuation zone.
#' @param roads Road/pathway network.
#' @param study_area Optional local study area used to crop candidate escape
#'   points to a broader region around the study area.
#' @param region_buffer_m Buffer distance passed to `make_region_area()` when
#'   `study_area` is supplied.
#' @return A point `SpatVector` of candidate escape/safety points.
#' @examples
#' r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
#'   vals = 1, crs = "EPSG:3857")
#' zone <- terra::as.polygons(r, dissolve = TRUE)
#' roads <- terra::vect(matrix(c(-1, 2, 5, 2), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' find_escape_points(zone, roads)
#' @export
find_escape_points <- function(
  hazard_zone,
  roads,
  study_area = NULL,
  region_buffer_m = 5000
) {
  hazard_zone <- .as_hazard_polygon(read_spatial(hazard_zone), dissolve = TRUE)
  roads <- read_spatial(roads)

  if (!inherits(roads, "SpatVector")) {
    stop("`roads` must be a SpatVector or vector file path.", call. = FALSE)
  }

  hazard_boundary <- .safe_as_lines(hazard_zone)
  roads_lines <- .safe_as_lines(roads)

  escape <- terra::intersect(roads_lines, hazard_boundary)
  .stop_empty(escape, "Road/hazard-boundary intersection")

  # terra can return mixed line/point geometry. Coordinate extraction gives a
  # stable point representation for least-cost destinations.
  coords <- terra::crds(escape, df = TRUE)
  if (!all(c("x", "y") %in% names(coords))) {
    names(coords)[1:2] <- c("x", "y")
  }
  escape <- terra::vect(coords[, c("x", "y"), drop = FALSE], geom = c("x", "y"), crs = terra::crs(hazard_zone))

  if (!is.null(study_area)) {
    region <- make_region_area(hazard_zone, study_area, buffer_m = region_buffer_m)
    escape <- terra::crop(escape, region, ext = TRUE)
  }

  .stop_empty(escape, "Escape points")
  escape
}
