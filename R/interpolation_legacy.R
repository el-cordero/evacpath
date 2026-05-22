#' Interpolate a distance surface from least-cost distance points
#'
#' Uses thin-plate spline interpolation to create a continuous distance surface.
#' This preserves the original paper-script approach while keeping interpolation
#' optional. For most package workflows, `make_evac_polygons()` is the simpler
#' output.
#'
#' @param distance_points Point layer with a distance column.
#' @param region_area Broader analysis region used for interpolation extent.
#' @param study_area Final study area used to crop and mask the output.
#' @param resolution_coarse Coarse interpolation resolution.
#' @param resolution_fine Fine output resolution.
#' @param distance_col Name of distance column in `distance_points`.
#' @return A `SpatRaster` distance surface.
#' @examples
#' if (requireNamespace("fields", quietly = TRUE)) {
#'   pts <- terra::vect(
#'     data.frame(
#'       x = c(0, 1, 0, 1, 0.5, 1.5),
#'       y = c(0, 0, 1, 1, 0.5, 1.5),
#'       distance = c(0, 5, 10, 15, 7, 20)
#'     ),
#'     geom = c("x", "y"),
#'     crs = "EPSG:3857"
#'   )
#'   area <- terra::as.polygons(terra::rast(nrows = 2, ncols = 2, xmin = -1, xmax = 2,
#'     ymin = -1, ymax = 2, vals = 1, crs = "EPSG:3857"), dissolve = TRUE)
#'   interpolate_distance_surface(pts, area, area, resolution_coarse = 0.5, resolution_fine = 1)
#' }
#' @export
interpolate_distance_surface <- function(
  distance_points,
  region_area,
  study_area,
  resolution_coarse = 100,
  resolution_fine = 1,
  distance_col = "distance"
) {
  if (!requireNamespace("fields", quietly = TRUE)) {
    stop("Package `fields` is required for thin-plate spline interpolation.", call. = FALSE)
  }

  distance_points <- read_spatial(distance_points)
  region_area <- read_spatial(region_area)
  study_area <- read_spatial(study_area)

  if (!distance_col %in% names(distance_points)) {
    stop("`distance_points` must contain column `", distance_col, "`.", call. = FALSE)
  }

  r1 <- terra::rast(
    resolution = resolution_coarse,
    crs = terra::crs(distance_points),
    extent = terra::ext(region_area)
  )

  dist_grid <- terra::rasterize(distance_points, r1, distance_col)
  xy <- data.frame(terra::xyFromCell(dist_grid, seq_len(terra::ncell(dist_grid))))
  v <- terra::values(dist_grid)
  if (is.matrix(v) || is.data.frame(v)) {
    v <- v[, 1]
  }
  keep <- !is.na(v)

  if (sum(keep) < 3L) {
    stop("At least three non-NA points are required for thin-plate spline interpolation.", call. = FALSE)
  }

  tps <- fields::Tps(xy[keep, ], v[keep])
  predict_tps <- function(model, x, ...) {
    fields::predict.Krig(model, as.matrix(x[, c("x", "y")]))
  }
  dist_grid <- terra::interpolate(dist_grid, tps, fun = predict_tps)
  dist_grid[dist_grid < 0] <- 0

  r2 <- terra::rast(
    resolution = resolution_fine,
    crs = terra::crs(distance_points),
    extent = terra::ext(region_area)
  )

  dist_grid <- terra::resample(dist_grid, r2)
  dist_grid <- terra::crop(dist_grid, study_area)
  terra::mask(dist_grid, study_area)
}
