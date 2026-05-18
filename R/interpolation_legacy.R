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
  dist_grid <- terra::interpolate(dist_grid, tps)
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

#' Backward-compatible alias for the original distance grid function
#'
#' @param minDist.pnts Minimum-distance points.
#' @param area.region Region area.
#' @param area.study Study area.
#' @param res.1 Coarse interpolation resolution.
#' @param res.2 Fine output resolution.
#' @return A `SpatRaster` distance surface.
#' @export
distance_grid <- function(minDist.pnts, area.region, area.study, res.1 = 100, res.2 = 1) {
  interpolate_distance_surface(
    distance_points = minDist.pnts,
    region_area = area.region,
    study_area = area.study,
    resolution_coarse = res.1,
    resolution_fine = res.2,
    distance_col = "distance"
  )
}
