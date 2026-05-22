#' Prepare a hazard zone from an inundation raster
#'
#' Converts an inundation raster to a binary hazard-zone raster or polygon using
#' a threshold. This is intentionally general so users can adapt it to tsunami,
#' flood, storm-surge, or other hazard layers.
#'
#' @param inundation A `SpatRaster` or path to a raster.
#' @param threshold Numeric threshold. Cells greater than `threshold` are treated
#'   as inside the hazard zone.
#' @param land_mask Optional `SpatRaster` or `SpatVector` used to mask the hazard
#'   zone to land.
#' @param target_crs Optional output CRS. Use a projected CRS in meters for later
#'   distance calculations.
#' @param as_polygon Logical. If `TRUE`, return a polygon hazard zone.
#' @param dissolve Logical. If `TRUE`, dissolve polygon pieces.
#' @return A binary `SpatRaster` or polygon `SpatVector`.
#' @examples
#' r <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5)
#' terra::values(r) <- c(rep(0, 12), rep(1, 13))
#' zone <- prepare_hazard_zone(r, threshold = 0, as_polygon = TRUE)
#' zone
#' @export
prepare_hazard_zone <- function(
  inundation,
  threshold = 0,
  land_mask = NULL,
  target_crs = NULL,
  as_polygon = TRUE,
  dissolve = TRUE
) {
  inundation <- read_spatial(inundation)

  if (!inherits(inundation, "SpatRaster")) {
    stop("`inundation` must be a raster or raster file path.", call. = FALSE)
  }

  if (!is.null(target_crs)) {
    inundation <- .project_to(inundation, target_crs)
  }

  hazard <- terra::ifel(inundation > threshold, 1, NA)

  if (!is.null(land_mask)) {
    land_mask <- read_spatial(land_mask)
    if (!is.null(target_crs)) {
      land_mask <- .project_to(land_mask, target_crs)
    }
    hazard <- terra::mask(hazard, land_mask)
  }

  if (isTRUE(as_polygon)) {
    hazard <- terra::as.polygons(hazard, dissolve = dissolve, na.rm = TRUE)
    if (dissolve) {
      hazard <- .safe_aggregate(hazard)
    }
  }

  hazard
}

#' Clean a road/pathway network
#'
#' Removes user-specified features from a road/pathway layer. This is useful for
#' excluding piers, tunnels, private ways, or other features that should not be
#' used in pedestrian evacuation modeling.
#'
#' @param roads A `SpatVector` or path to a vector layer.
#' @param exclude Optional named list with `field` and `values`, for example
#'   `list(field = "man_made", values = "pier")`.
#' @param target_crs Optional output CRS.
#' @return A cleaned `SpatVector`.
#' @examples
#' roads <- terra::vect(
#'   list(
#'     matrix(c(0, 0, 0, 1), ncol = 2, byrow = TRUE),
#'     matrix(c(1, 0, 1, 1), ncol = 2, byrow = TRUE)
#'   ),
#'   type = "lines",
#'   crs = "EPSG:3857"
#' )
#' roads$kind <- c("road", "pier")
#' clean_roads(roads, exclude = list(field = "kind", values = "pier"))
#' @export
clean_roads <- function(roads, exclude = NULL, target_crs = NULL) {
  roads <- read_spatial(roads)

  if (!inherits(roads, "SpatVector")) {
    stop("`roads` must be a vector layer or vector file path.", call. = FALSE)
  }

  if (!is.null(target_crs)) {
    roads <- .project_to(roads, target_crs)
  }

  if (!is.null(exclude)) {
    if (!all(c("field", "values") %in% names(exclude))) {
      stop("`exclude` must be a list with elements `field` and `values`.", call. = FALSE)
    }
    if (!.has_column(roads, exclude$field)) {
      warning("Road exclusion field not found: ", exclude$field, call. = FALSE)
    } else {
      values <- terra::values(roads)[[exclude$field]]
      keep <- !(values %in% exclude$values)
      keep[is.na(keep)] <- TRUE
      roads <- roads[keep, ]
    }
  }

  .stop_empty(roads, "Road network")
  roads
}

#' Read and project the core evacuation inputs
#'
#' @param hazard_zone Hazard/inundation zone as a `SpatRaster`, `SpatVector`, or file path.
#' @param roads Road/pathway network as a `SpatVector` or file path.
#' @param dem Elevation raster as a `SpatRaster` or file path.
#' @param target_crs Optional projected CRS in meters.
#' @param hazard_as_polygon Logical. Convert raster hazard zones to polygons.
#' @param dissolve_hazard Logical. Dissolve hazard polygon pieces.
#' @param road_exclude Optional road exclusion list passed to `clean_roads()`.
#' @return A named list with `hazard_zone`, `roads`, and `dem`.
#' @examples
#' dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
#'   vals = 1, crs = "EPSG:3857")
#' hazard <- terra::as.polygons(dem, dissolve = TRUE)
#' roads <- terra::vect(matrix(c(0, 2.5, 5, 2.5), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' inputs <- prepare_evac_inputs(hazard, roads, dem)
#' names(inputs)
#' @export
prepare_evac_inputs <- function(
  hazard_zone,
  roads,
  dem,
  target_crs = NULL,
  hazard_as_polygon = TRUE,
  dissolve_hazard = TRUE,
  road_exclude = NULL
) {
  hazard_zone <- read_spatial(hazard_zone)
  roads <- clean_roads(roads, exclude = road_exclude)
  dem <- read_spatial(dem)

  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` must be a raster or raster file path.", call. = FALSE)
  }

  if (!is.null(target_crs)) {
    hazard_zone <- .project_to(hazard_zone, target_crs)
    roads <- .project_to(roads, target_crs)
    dem <- .project_to(dem, target_crs)
  }

  if (isTRUE(hazard_as_polygon)) {
    hazard_zone <- .as_hazard_polygon(hazard_zone, dissolve = dissolve_hazard)
  }

  list(
    hazard_zone = hazard_zone,
    roads = roads,
    dem = dem,
    target_crs = target_crs
  )
}
