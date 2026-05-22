#' Crop roads to an inset extent before escape-point detection
#'
#' Crops a road/pathway layer to a slightly reduced bounding box around a zone.
#' This is useful before escape-point detection because roads extending beyond the
#' study-area coverage can intersect artificial raster or polygon extent edges and
#' create false escape/safety points.
#'
#' @param roads Road/pathway network as a `SpatVector` or file path.
#' @param zone Zone used to define the outer extent. Can be a `SpatVector`,
#'   `SpatRaster`, or file path.
#' @param inset_x_m Numeric. Distance to inset the minimum and maximum x
#'   boundaries, in map units. Use meters when the data are projected.
#' @param inset_y_m Numeric. Distance to inset the minimum and maximum y
#'   boundaries, in map units. Use meters when the data are projected.
#'
#' @return A cropped road/pathway `SpatVector`.
#' @examples
#' r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
#'   vals = 1, crs = "EPSG:3857")
#' zone <- terra::as.polygons(r, dissolve = TRUE)
#' roads <- terra::vect(matrix(c(-1, 2, 5, 2), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' crop_roads_to_inner_extent(roads, zone, inset_x_m = 0.5, inset_y_m = 0)
#' @export
crop_roads_to_inner_extent <- function(
  roads,
  zone,
  inset_x_m = 250,
  inset_y_m = 250
) {
  roads <- read_spatial(roads)
  zone <- read_spatial(zone)

  if (!inherits(roads, "SpatVector")) {
    stop("`roads` must be a terra SpatVector or vector file path.", call. = FALSE)
  }

  if (!inherits(zone, c("SpatVector", "SpatRaster"))) {
    stop("`zone` must be a terra SpatVector, SpatRaster, or spatial file path.", call. = FALSE)
  }

  inset_x_m <- as.numeric(inset_x_m)
  inset_y_m <- as.numeric(inset_y_m)

  if (length(inset_x_m) != 1L || is.na(inset_x_m) || inset_x_m < 0) {
    stop("`inset_x_m` must be a single non-negative number.", call. = FALSE)
  }

  if (length(inset_y_m) != 1L || is.na(inset_y_m) || inset_y_m < 0) {
    stop("`inset_y_m` must be a single non-negative number.", call. = FALSE)
  }

  e <- terra::ext(zone)
  width_x <- terra::xmax(e) - terra::xmin(e)
  width_y <- terra::ymax(e) - terra::ymin(e)

  if (width_x <= 2 * inset_x_m) {
    stop("`inset_x_m` is too large for the zone extent.", call. = FALSE)
  }

  if (width_y <= 2 * inset_y_m) {
    stop("`inset_y_m` is too large for the zone extent.", call. = FALSE)
  }

  inner_extent <- terra::ext(
    terra::xmin(e) + inset_x_m,
    terra::xmax(e) - inset_x_m,
    terra::ymin(e) + inset_y_m,
    terra::ymax(e) - inset_y_m
  )

  out <- terra::crop(roads, inner_extent)
  .stop_empty(out, "Roads cropped to inner extent")
  out
}

#' Add buffered road corridors to an escape-boundary zone
#'
#' Creates a road-aware escape zone by combining a base escape zone with buffered
#' road/pathway corridors. This is useful for tsunami workflows in coastal cities
#' where bridges, causeways, or other walkways over water can be lost when the
#' inundation layer is split into land and water masks. The resulting object can
#' be passed to `find_escape_points()` so escape/safety points are generated from
#' a boundary that includes relevant road corridors as well as the tsunami zone.
#'
#' @param escape_zone Base escape-boundary zone, usually the land-inundation-plus-
#'   water zone from `prepare_tsunami_zones()`.
#' @param roads Road/pathway network used to create the road-aware corridor.
#' @param road_buffer_m First road buffer distance in map units.
#' @param crop_buffer_m Optional second buffer applied before cropping/combining.
#' @param include_base_zone Logical. If `TRUE`, combine the buffered roads with
#'   the original `escape_zone`. If `FALSE`, only the buffered road corridor is
#'   returned.
#'
#' @return A dissolved `SpatVector` escape-boundary zone.
#' @examples
#' r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
#'   vals = 1, crs = "EPSG:3857")
#' zone <- terra::as.polygons(r, dissolve = TRUE)
#' roads <- terra::vect(matrix(c(0, 2, 4, 2), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' make_road_aware_escape_zone(zone, roads, road_buffer_m = 0.1)
#' @export
make_road_aware_escape_zone <- function(
  escape_zone,
  roads,
  road_buffer_m = 2,
  crop_buffer_m = 3,
  include_base_zone = TRUE
) {
  make_roads_in_zone(
    roads = roads,
    zone = escape_zone,
    road_buffer_m = road_buffer_m,
    crop_buffer_m = crop_buffer_m,
    include_zone = include_base_zone
  )
}
