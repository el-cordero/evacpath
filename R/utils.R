# Internal utilities ---------------------------------------------------------

.raster_ext <- c("tif", "tiff", "img", "grd", "nc", "asc")
.vector_ext <- c("gpkg", "shp", "geojson", "json", "kml", "gml")

#' Read a spatial input
#'
#' Accepts an existing `terra` object or a file path and returns a `SpatRaster`
#' or `SpatVector`. Raster-like extensions are read with [terra::rast()] and
#' vector-like extensions are read with [terra::vect()].
#'
#' @param x A `SpatRaster`, `SpatVector`, or file path.
#' @return A `SpatRaster` or `SpatVector`.
#' @export
read_spatial <- function(x) {
  if (inherits(x, c("SpatRaster", "SpatVector"))) {
    return(x)
  }

  if (!is.character(x) || length(x) != 1L) {
    stop("Input must be a SpatRaster, SpatVector, or single file path.", call. = FALSE)
  }

  if (!file.exists(x)) {
    stop("File does not exist: ", x, call. = FALSE)
  }

  ext <- tolower(utils::tail(strsplit(x, "\\.")[[1]], 1L))

  if (ext %in% .raster_ext) {
    return(terra::rast(x))
  }

  if (ext %in% .vector_ext) {
    return(terra::vect(x))
  }

  stop(
    "Unknown spatial file extension: .", ext,
    ". Use a terra SpatRaster/SpatVector or a known raster/vector file.",
    call. = FALSE
  )
}

.project_to <- function(x, target_crs = NULL) {
  if (is.null(target_crs)) {
    return(x)
  }

  if (is.na(terra::crs(x))) {
    stop("Cannot project an object with a missing CRS.", call. = FALSE)
  }

  terra::project(x, target_crs)
}

.as_hazard_polygon <- function(x, dissolve = TRUE) {
  if (inherits(x, "SpatRaster")) {
    # Assumes non-NA cells represent the hazard area. Users can prepare the
    # raster with prepare_hazard_zone() when a threshold is needed.
    x <- terra::as.polygons(x, dissolve = dissolve, na.rm = TRUE)
  }

  if (!inherits(x, "SpatVector")) {
    stop("Hazard zone must be a SpatRaster or SpatVector.", call. = FALSE)
  }

  if (dissolve) {
    x <- .safe_aggregate(x)
  }

  x
}

.safe_aggregate <- function(x) {
  tryCatch(
    terra::aggregate(x, dissolve = TRUE),
    error = function(e) terra::aggregate(x)
  )
}

.safe_as_lines <- function(x) {
  tryCatch(
    terra::as.lines(x),
    error = function(e) {
      stop("Could not convert object to lines: ", conditionMessage(e), call. = FALSE)
    }
  )
}

.combine_vectors <- function(...) {
  xs <- list(...)
  xs <- xs[!vapply(xs, is.null, logical(1))]

  if (length(xs) == 0L) {
    return(NULL)
  }
  if (length(xs) == 1L) {
    return(xs[[1]])
  }

  out <- xs[[1]]
  for (i in seq.int(2L, length(xs))) {
    out <- tryCatch(
      rbind(out, xs[[i]]),
      error = function(e) terra::vect(c(out, xs[[i]]))
    )
  }
  out
}

.has_column <- function(x, name) {
  name %in% names(x)
}

.stop_empty <- function(x, what) {
  n <- tryCatch(nrow(x), error = function(e) NA_integer_)
  if (is.na(n)) {
    n <- tryCatch(length(x), error = function(e) NA_integer_)
  }
  if (!is.na(n) && n == 0L) {
    stop(what, " is empty.", call. = FALSE)
  }
  invisible(x)
}
