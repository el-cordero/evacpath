#' Write evacpath outputs to disk
#'
#' Writes the main spatial outputs in an `evacpath_result` list to GeoPackage and
#' GeoTIFF files. Non-spatial objects, including the conductance surface, are not
#' written.
#'
#' @param result An object returned by `run_evacpath()`.
#' @param output_dir Output directory.
#' @param prefix Filename prefix.
#' @param overwrite Logical. Overwrite existing files.
#' @param include_inputs Logical. Also write projected input layers.
#' @return A named character vector of written file paths.
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
#' out_dir <- file.path(tempdir(), "evacpath-example")
#' paths <- write_evac_outputs(result, output_dir = out_dir, prefix = "example")
#' unlink(out_dir, recursive = TRUE)
#' @export
write_evac_outputs <- function(
  result,
  output_dir,
  prefix = "evacpath",
  overwrite = TRUE,
  include_inputs = FALSE
) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  vector_names <- c(
    "evac_grid",
    "escape_points",
    "road_mask",
    "roads_buffer",
    "escape_buffer",
    "road_points",
    "distance_points",
    "clip_area",
    "evac_polygons",
    "time_grid"
  )

  raster_names <- character(0)

  if (isTRUE(include_inputs)) {
    vector_names <- c("hazard_zone", "escape_zone", "roads", "study_area", vector_names)
    raster_names <- c("dem", raster_names)
  }

  written <- character(0)

  for (nm in unique(vector_names)) {
    obj <- result[[nm]]
    if (is.null(obj) || !inherits(obj, "SpatVector")) {
      next
    }
    path <- file.path(output_dir, paste0(prefix, "_", nm, ".gpkg"))
    terra::writeVector(obj, path, overwrite = overwrite)
    written[nm] <- path
  }

  for (nm in unique(raster_names)) {
    obj <- result[[nm]]
    if (is.null(obj) || !inherits(obj, "SpatRaster")) {
      next
    }
    path <- file.path(output_dir, paste0(prefix, "_", nm, ".tif"))
    terra::writeRaster(obj, path, overwrite = overwrite)
    written[nm] <- path
  }

  written
}
