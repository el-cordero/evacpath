#' Prepare separate tsunami zones for escape analysis and visualization
#'
#' Tsunami evacuation workflows often need two different zone objects. The
#' land-only inundation zone is the area where road origins and output time
#' surfaces should be mapped. The escape-boundary zone should combine the
#' land-only inundation zone with water so that the coastline is not treated as
#' an artificial escape boundary. This prevents false escape/safety points along
#' the water-land edge when roads touch or approach the shoreline.
#'
#' @param inundation Inundation-depth raster or path to a raster. Cells greater
#'   than `inundation_threshold` are treated as inundated.
#' @param dem Elevation/topobathymetry raster or path to a raster.
#' @param target_crs Optional projected CRS in meters for returned objects.
#' @param inundation_threshold Numeric threshold used to define inundated cells.
#' @param land_threshold Numeric DEM threshold used to define land. Default is
#'   `0`, so land is `dem > 0` after applying `dem_sign_multiplier`.
#' @param water_threshold Numeric DEM threshold used to define water. Default is
#'   `0`, so water is `dem < 0` after applying `dem_sign_multiplier`.
#' @param dem_sign_multiplier Multiplier applied to the DEM before land/water
#'   classification. Use `-1` when the DEM sign convention is reversed.
#' @param resample_method Method passed to `terra::resample()` when aligning the
#'   inundation raster to the DEM. Use `"bilinear"` for depth rasters and
#'   `"near"` for categorical rasters.
#' @param as_polygon Logical. If `TRUE`, return polygon zones in addition to
#'   rasters.
#' @param dissolve Logical. Dissolve polygon pieces.
#'
#' @return A named list with land-only `hazard_zone`, water-combined
#'   `escape_zone`, and supporting rasters. `hazard_zone` should usually be used
#'   for origin generation, mapping, and output clipping. `escape_zone` should
#'   usually be passed to `run_evacpath(escape_zone = ...)` or
#'   `find_escape_points()`.
#' @export
prepare_tsunami_zones <- function(
  inundation,
  dem,
  target_crs = NULL,
  inundation_threshold = 0,
  land_threshold = 0,
  water_threshold = 0,
  dem_sign_multiplier = 1,
  resample_method = "bilinear",
  as_polygon = TRUE,
  dissolve = TRUE
) {
  inundation <- read_spatial(inundation)
  dem <- read_spatial(dem)

  if (!inherits(inundation, "SpatRaster")) {
    stop("`inundation` must be a SpatRaster or raster file path.", call. = FALSE)
  }
  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` must be a SpatRaster or raster file path.", call. = FALSE)
  }

  dem_work <- dem * dem_sign_multiplier

  # Align the inundation raster to the DEM grid before masking by land/water.
  if (!terra::same.crs(inundation, dem_work)) {
    inundation <- terra::project(inundation, dem_work)
  }
  inundation <- terra::resample(inundation, dem_work, method = resample_method)

  land_mask <- terra::ifel(dem_work > land_threshold, 1, NA)
  water_mask <- terra::ifel(dem_work < water_threshold, 1, NA)

  inundation_land <- terra::mask(inundation, land_mask)
  hazard_land <- terra::ifel(inundation_land > inundation_threshold, 1, NA)

  # This is the important tsunami-specific step: combine the land inundation
  # footprint with water so the coast is not interpreted as a safety boundary.
  escape_raster <- terra::mosaic(hazard_land, water_mask)

  out <- list(
    hazard_raster = hazard_land,
    escape_raster = escape_raster,
    land_mask = land_mask,
    water_mask = water_mask,
    inundation_aligned = inundation,
    dem = dem_work
  )

  if (isTRUE(as_polygon)) {
    hazard_zone <- terra::as.polygons(hazard_land, dissolve = dissolve, na.rm = TRUE)
    escape_zone <- terra::as.polygons(escape_raster, dissolve = dissolve, na.rm = TRUE)

    if (dissolve) {
      hazard_zone <- .safe_aggregate(hazard_zone)
      escape_zone <- .safe_aggregate(escape_zone)
    }

    if (!is.null(target_crs)) {
      hazard_zone <- .project_to(hazard_zone, target_crs)
      escape_zone <- .project_to(escape_zone, target_crs)
    }

    out$hazard_zone <- hazard_zone
    out$escape_zone <- escape_zone
  }

  if (!is.null(target_crs)) {
    out$hazard_raster <- .project_to(out$hazard_raster, target_crs)
    out$escape_raster <- .project_to(out$escape_raster, target_crs)
    out$land_mask <- .project_to(out$land_mask, target_crs)
    out$water_mask <- .project_to(out$water_mask, target_crs)
    out$inundation_aligned <- .project_to(out$inundation_aligned, target_crs)
    out$dem <- .project_to(out$dem, target_crs)
  }

  class(out) <- c("evacpath_tsunami_zones", class(out))
  out
}

#' Create a buffered road area inside an inundation or analysis zone
#'
#' Mirrors the original script logic where roads were buffered, optionally
#' buffered again for tolerance, cropped to the inundation zone, and then
#' combined with the zone. This is useful for QA/QC and for reproducing the
#' earlier road-plus-inundation analysis area.
#'
#' @param roads Road/pathway network.
#' @param zone Polygon/raster zone used to crop buffered roads.
#' @param road_buffer_m First road buffer distance.
#' @param crop_buffer_m Optional second buffer applied before cropping.
#' @param include_zone Logical. If `TRUE`, combine the cropped road buffer with
#'   `zone` and dissolve the result.
#' @return A `SpatVector`.
#' @export
make_roads_in_zone <- function(
  roads,
  zone,
  road_buffer_m = 2,
  crop_buffer_m = 3,
  include_zone = TRUE
) {
  roads <- read_spatial(roads)
  zone <- .as_hazard_polygon(read_spatial(zone), dissolve = TRUE)

  roads_buffer <- terra::buffer(roads, road_buffer_m)
  roads_buffer <- .safe_aggregate(roads_buffer)

  crop_buffer <- terra::buffer(roads_buffer, crop_buffer_m)
  roads_in_zone <- terra::crop(crop_buffer, zone)
  roads_in_zone <- .safe_aggregate(roads_in_zone)

  if (isTRUE(include_zone)) {
    roads_in_zone <- .combine_vectors(roads_in_zone, zone)
    roads_in_zone <- .safe_aggregate(roads_in_zone)
  }

  roads_in_zone
}

#' @export
print.evacpath_tsunami_zones <- function(x, ...) {
  cat("<evacpath_tsunami_zones>\n")
  cat("Use `hazard_zone` for land-only origins/output mapping.\n")
  cat("Use `escape_zone` for escape-point detection so coastline boundaries are not treated as safety exits.\n")
  invisible(x)
}
