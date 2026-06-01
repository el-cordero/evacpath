.diagnostic_has_crs <- function(x) {
  if (is.null(x)) {
    return(FALSE)
  }
  crs <- tryCatch(terra::crs(x), error = function(e) NA_character_)
  is.character(crs) && length(crs) == 1L && !is.na(crs) && nzchar(crs)
}

.diagnostic_same_crs <- function(x, target_crs) {
  if (!.diagnostic_has_crs(x)) {
    return(FALSE)
  }
  tryCatch(terra::same.crs(x, target_crs), error = function(e) FALSE)
}

.diagnostic_geomtype <- function(x) {
  tryCatch(tolower(terra::geomtype(x)), error = function(e) character())
}

.diagnostic_invalid_count <- function(x) {
  valid <- tryCatch(terra::is.valid(x), error = function(e) logical())
  sum(!valid, na.rm = TRUE)
}

.diagnostic_empty_geom_count <- function(x) {
  empty <- tryCatch(terra::is.empty(x), error = function(e) logical())
  sum(empty, na.rm = TRUE)
}

.diagnostic_intersects <- function(x, y) {
  if (is.null(x) || is.null(y) || nrow(x) == 0L || nrow(y) == 0L) {
    return(logical())
  }
  relation <- tryCatch(
    terra::relate(x, y, relation = "intersects"),
    error = function(e) NULL
  )
  if (is.null(relation)) {
    return(rep(FALSE, nrow(x)))
  }
  if (is.matrix(relation)) {
    return(rowSums(relation) > 0)
  }
  as.logical(relation)
}

.diagnostic_extents_overlap <- function(x, y) {
  x_ext <- tryCatch(as.vector(terra::ext(x)), error = function(e) rep(NA_real_, 4))
  y_ext <- tryCatch(as.vector(terra::ext(y)), error = function(e) rep(NA_real_, 4))
  if (anyNA(c(x_ext, y_ext))) {
    return(FALSE)
  }
  x_ext[1] < y_ext[2] && x_ext[2] > y_ext[1] &&
    x_ext[3] < y_ext[4] && x_ext[4] > y_ext[3]
}

.diagnostic_extract_values <- function(raster, points) {
  extracted <- tryCatch(terra::extract(raster, points), error = function(e) NULL)
  if (is.null(extracted) || ncol(extracted) < 2L) {
    return(rep(NA_real_, nrow(points)))
  }
  as.numeric(extracted[[2]])
}

#' Diagnose evacuation-model inputs
#'
#' Runs spatial quality assurance and quality control checks before or after
#' evacuation modeling. Unlike the modeling workflow, diagnostics collect issues
#' into a report so several input problems can be reviewed together.
#'
#' @param hazard_zone Hazard-zone polygon, raster, or file path.
#' @param roads Road/pathway line layer or file path.
#' @param dem Digital elevation model raster or file path.
#' @param target_crs Optional target coordinate reference system.
#' @param escape_zone Optional escape-boundary zone.
#' @param origins Optional modeled origin points.
#' @param destinations Optional escape/safety destination points.
#' @param conductance Optional `leastcostpath` conductance surface. When supplied
#'   with origins and destinations, routing checks are run.
#' @param check_reachability Logical. Attempt sampled routing checks when routing
#'   inputs are available.
#' @param sample_size Maximum number of origins used for sampled reachability
#'   checks.
#' @param ... Reserved for future extensions.
#' @return An `evac_diagnostics` list with `issues`, `summary`,
#'   `diagnostic_layers`, and `metadata`.
#' @examples
#' dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
#'   vals = 1, crs = "EPSG:3857")
#' hazard <- terra::as.polygons(dem, dissolve = TRUE)
#' roads <- terra::vect(matrix(c(0, 2.5, 5, 2.5), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' diagnostics <- diagnose_evac_model(hazard, roads, dem)
#' diagnostics
#' has_errors(diagnostics)
#' @export
diagnose_evac_model <- function(
  hazard_zone,
  roads,
  dem,
  target_crs = NULL,
  escape_zone = NULL,
  origins = NULL,
  destinations = NULL,
  conductance = NULL,
  check_reachability = TRUE,
  sample_size = 100,
  ...
) {
  if (!is.numeric(sample_size) || length(sample_size) != 1L ||
      is.na(sample_size) || !is.finite(sample_size) || sample_size < 1) {
    stop("`sample_size` must be a single positive numeric value.", call. = FALSE)
  }
  sample_size <- as.integer(sample_size)

  issues <- list()
  add_issue <- function(severity, check, message, n_affected = NA_integer_) {
    issues[[length(issues) + 1L]] <<- data.frame(
      severity = severity,
      check = check,
      message = message,
      n_affected = as.integer(n_affected),
      stringsAsFactors = FALSE
    )
  }

  read_for_diagnostics <- function(x, label, required = FALSE) {
    if (is.null(x)) {
      if (isTRUE(required)) {
        add_issue("error", "input", paste0("`", label, "` is missing."), 1L)
      }
      return(NULL)
    }
    tryCatch(
      {
        if (inherits(x, "sf")) terra::vect(x) else read_spatial(x)
      },
      error = function(e) {
        add_issue("error", "input", paste0("Could not read `", label, "`: ", conditionMessage(e)), 1L)
        NULL
      }
    )
  }

  hazard_zone <- read_for_diagnostics(hazard_zone, "hazard_zone", required = TRUE)
  roads <- read_for_diagnostics(roads, "roads", required = TRUE)
  dem <- read_for_diagnostics(dem, "dem", required = TRUE)
  escape_zone <- read_for_diagnostics(escape_zone, "escape_zone")
  origins <- read_for_diagnostics(origins, "origins")
  destinations <- read_for_diagnostics(destinations, "destinations")

  spatial_inputs <- list(
    hazard_zone = hazard_zone,
    roads = roads,
    dem = dem,
    escape_zone = escape_zone,
    origins = origins,
    destinations = destinations
  )

  for (name in names(spatial_inputs)) {
    x <- spatial_inputs[[name]]
    if (is.null(x)) {
      next
    }
    if (!.diagnostic_has_crs(x)) {
      add_issue("error", "crs", paste0("`", name, "` is missing a coordinate reference system."), 1L)
    } else if (!is.null(target_crs) && !.diagnostic_same_crs(x, target_crs)) {
      add_issue(
        "warning",
        "crs",
        paste0("`", name, "` does not match `target_crs` but can be transformed before modeling."),
        1L
      )
    }
  }

  vector_inputs <- spatial_inputs[vapply(spatial_inputs, inherits, logical(1), what = "SpatVector")]
  for (name in names(vector_inputs)) {
    x <- vector_inputs[[name]]
    if (nrow(x) == 0L) {
      add_issue("error", "geometry", paste0("`", name, "` is empty."), 0L)
      next
    }
    n_empty <- .diagnostic_empty_geom_count(x)
    if (n_empty > 0L) {
      add_issue("error", "geometry", paste0("`", name, "` contains empty geometries."), n_empty)
    }
    n_invalid <- .diagnostic_invalid_count(x)
    if (n_invalid > 0L) {
      add_issue("warning", "geometry", paste0("`", name, "` contains invalid geometries."), n_invalid)
    }
  }

  if (!is.null(roads) && !inherits(roads, "SpatVector")) {
    add_issue("error", "geometry", "`roads` must be a vector line layer.", 1L)
  }
  if (!is.null(dem) && !inherits(dem, "SpatRaster")) {
    add_issue("error", "dem", "`dem` must be a raster.", 1L)
  }

  if (!is.null(hazard_zone) && inherits(hazard_zone, "SpatVector") &&
      nrow(hazard_zone) > 0L &&
      !all(grepl("polygon", .diagnostic_geomtype(hazard_zone)))) {
    add_issue("error", "geometry", "`hazard_zone` must contain polygon geometries.", nrow(hazard_zone))
  }
  if (!is.null(roads) && inherits(roads, "SpatVector") && nrow(roads) > 0L &&
      !all(grepl("line", .diagnostic_geomtype(roads)))) {
    add_issue("error", "geometry", "`roads` must contain line geometries.", nrow(roads))
  }

  diagnostic_layers <- list()
  if (!is.null(hazard_zone) && !is.null(roads) &&
      inherits(hazard_zone, "SpatVector") && inherits(roads, "SpatVector") &&
      nrow(hazard_zone) > 0L && nrow(roads) > 0L) {
    roads_in_hazard <- .diagnostic_intersects(roads, hazard_zone)
    if (!any(roads_in_hazard)) {
      add_issue("error", "overlap", "`roads` do not intersect `hazard_zone`.", nrow(roads))
    }
  }

  if (!is.null(hazard_zone) && !is.null(dem) &&
      inherits(dem, "SpatRaster") && !.diagnostic_extents_overlap(dem, hazard_zone)) {
    add_issue("error", "overlap", "`dem` does not overlap `hazard_zone`.", 1L)
  }

  if (!is.null(escape_zone) && !is.null(hazard_zone) &&
      inherits(escape_zone, "SpatVector") && inherits(hazard_zone, "SpatVector") &&
      nrow(escape_zone) > 0L && nrow(hazard_zone) > 0L) {
    escape_outside_hazard <- tryCatch(
      terra::erase(escape_zone, hazard_zone),
      error = function(e) NULL
    )
    if (is.null(escape_outside_hazard) || nrow(escape_outside_hazard) == 0L) {
      add_issue(
        "warning",
        "escape_zone",
        "`escape_zone` does not extend outside `hazard_zone`; verify that it represents intended safety boundaries.",
        1L
      )
    } else {
      diagnostic_layers$escape_zone_outside_hazard <- escape_outside_hazard
      add_issue("info", "escape_zone", "`escape_zone` includes area outside `hazard_zone`.", nrow(escape_outside_hazard))
    }
  }

  if (!is.null(origins) && !is.null(hazard_zone) &&
      inherits(origins, "SpatVector") && inherits(hazard_zone, "SpatVector") &&
      nrow(origins) > 0L && nrow(hazard_zone) > 0L) {
    origins_inside <- .diagnostic_intersects(origins, hazard_zone)
    if (any(!origins_inside)) {
      diagnostic_layers$origins_outside_hazard <- origins[!origins_inside, ]
      add_issue("error", "origins", "Some origins fall outside `hazard_zone`.", sum(!origins_inside))
    }
  }

  if (!is.null(destinations) && inherits(destinations, "SpatVector")) {
    if (nrow(destinations) == 0L) {
      add_issue("error", "destinations", "`destinations` is empty.", 0L)
    } else if (!is.null(hazard_zone) && inherits(hazard_zone, "SpatVector") &&
               nrow(hazard_zone) > 0L) {
      destinations_in_hazard <- .diagnostic_intersects(destinations, hazard_zone)
      if (any(!destinations_in_hazard)) {
        diagnostic_layers$destinations_outside_hazard <- destinations[!destinations_in_hazard, ]
        add_issue(
          "info",
          "destinations",
          "Some destinations fall outside `hazard_zone`; verify that these are intended safety exits.",
          sum(!destinations_in_hazard)
        )
      }
    }
    if (!is.null(escape_zone) && inherits(escape_zone, "SpatVector") &&
        nrow(destinations) > 0L && nrow(escape_zone) > 0L) {
      destinations_in_escape <- .diagnostic_intersects(destinations, escape_zone)
      if (any(!destinations_in_escape)) {
        add_issue(
          "warning",
          "destinations",
          "Some destinations do not intersect `escape_zone`.",
          sum(!destinations_in_escape)
        )
      }
    }
  }

  dem_resolution <- c(NA_real_, NA_real_)
  if (!is.null(dem) && inherits(dem, "SpatRaster")) {
    dem_resolution <- terra::res(dem)
    if (!.diagnostic_has_crs(dem)) {
      add_issue("warning", "dem", "`dem` resolution cannot be interpreted without a coordinate reference system.", 1L)
    } else if (terra::is.lonlat(dem)) {
      add_issue("warning", "dem", "`dem` uses a geographic coordinate reference system; use a projected CRS for routing.", 1L)
    }

    if (!is.null(hazard_zone) && inherits(hazard_zone, "SpatVector") &&
        .diagnostic_extents_overlap(dem, hazard_zone)) {
      zone_cells <- tryCatch(
        terra::rasterize(hazard_zone, dem, field = 1),
        error = function(e) NULL
      )
      if (!is.null(zone_cells)) {
        inside <- is.finite(as.numeric(terra::values(zone_cells)[, 1]))
        dem_values <- as.numeric(terra::values(dem)[, 1])
        n_missing <- sum(inside & !is.finite(dem_values))
        if (n_missing > 0L) {
          add_issue("warning", "dem", "`dem` has missing values within `hazard_zone`.", n_missing)
        }
      }
    }
  }

  n_sampled <- 0L
  n_unreachable <- 0L
  if (isTRUE(check_reachability) && !is.null(conductance) &&
      !is.null(origins) && !is.null(destinations) &&
      inherits(origins, "SpatVector") && inherits(destinations, "SpatVector") &&
      nrow(origins) > 0L && nrow(destinations) > 0L) {
    conductance_raster <- tryCatch(
      leastcostpath::rasterise(conductance),
      error = function(e) {
        add_issue("error", "routing", paste0("Could not rasterise `conductance`: ", conditionMessage(e)), 1L)
        NULL
      }
    )

    if (!is.null(conductance_raster)) {
      route_origins <- origins
      route_destinations <- destinations
      if (.diagnostic_has_crs(route_origins)) {
        route_origins <- terra::project(route_origins, terra::crs(conductance_raster))
      }
      if (.diagnostic_has_crs(route_destinations)) {
        route_destinations <- terra::project(route_destinations, terra::crs(conductance_raster))
      }

      origin_values <- .diagnostic_extract_values(conductance_raster, route_origins)
      destination_values <- .diagnostic_extract_values(conductance_raster, route_destinations)
      off_surface_origins <- !is.finite(origin_values) | origin_values <= 0
      off_surface_destinations <- !is.finite(destination_values) | destination_values <= 0
      if (any(off_surface_origins)) {
        diagnostic_layers$origins_off_conductance <- origins[off_surface_origins, ]
        add_issue("warning", "routing", "Some origins are not on traversable conductance cells.", sum(off_surface_origins))
      }
      if (any(off_surface_destinations)) {
        diagnostic_layers$destinations_off_conductance <- destinations[off_surface_destinations, ]
        add_issue("warning", "routing", "Some destinations are not on traversable conductance cells.", sum(off_surface_destinations))
      }

      sampled_ids <- seq_len(min(sample_size, nrow(route_origins)))
      n_sampled <- length(sampled_ids)
      reachable <- vapply(
        sampled_ids,
        function(i) {
          path <- tryCatch(
            leastcostpath::create_lcp(
              x = conductance,
              origin = route_origins[i, ],
              destination = route_destinations,
              check_locations = TRUE
            ),
            error = function(e) NULL
          )
          !is.null(path) && nrow(path) > 0L
        },
        logical(1)
      )
      n_unreachable <- sum(!reachable)
      if (n_unreachable > 0L) {
        diagnostic_layers$unreachable_origins <- origins[sampled_ids[!reachable], ]
        add_issue(
          "warning",
          "routing",
          "Some sampled origins could not be connected to a destination.",
          n_unreachable
        )
      }
    }
  } else if (isTRUE(check_reachability)) {
    add_issue(
      "info",
      "routing",
      "Reachability checks were skipped because conductance, origins, and destinations were not all supplied.",
      NA_integer_
    )
  }

  issues <- if (length(issues) > 0L) {
    do.call(rbind, issues)
  } else {
    data.frame(
      severity = character(),
      check = character(),
      message = character(),
      n_affected = integer(),
      stringsAsFactors = FALSE
    )
  }

  out <- list(
    issues = issues,
    summary = data.frame(
      n_errors = sum(issues$severity == "error"),
      n_warnings = sum(issues$severity == "warning"),
      n_info = sum(issues$severity == "info"),
      n_roads = .spatial_nrow(roads),
      n_origins = .spatial_nrow(origins),
      n_destinations = .spatial_nrow(destinations),
      dem_resolution_x = dem_resolution[1],
      dem_resolution_y = dem_resolution[2],
      n_sampled_origins = n_sampled,
      n_unreachable_sampled_origins = n_unreachable,
      pct_unreachable_sampled_origins = if (n_sampled > 0L) n_unreachable / n_sampled * 100 else NA_real_
    ),
    diagnostic_layers = diagnostic_layers,
    metadata = list(
      target_crs = target_crs,
      check_reachability = check_reachability,
      sample_size = sample_size
    )
  )
  class(out) <- c("evac_diagnostics", "list")
  out
}

#' @export
print.evac_diagnostics <- function(x, ...) {
  cat("<evac_diagnostics>\n")
  cat(
    "Errors: ", x$summary$n_errors,
    " | Warnings: ", x$summary$n_warnings,
    " | Info: ", x$summary$n_info, "\n",
    sep = ""
  )
  if (nrow(x$issues) > 0L) {
    print(x$issues, row.names = FALSE)
  }
  invisible(x)
}

#' Test whether diagnostics contain errors
#'
#' @param x An object returned by [diagnose_evac_model()].
#' @param ... Additional arguments passed to methods.
#' @return Logical value indicating whether diagnostics contain at least one
#'   error.
#' @examples
#' dem <- terra::rast(nrows = 2, ncols = 2, vals = 1, crs = "EPSG:3857")
#' hazard <- terra::as.polygons(dem, dissolve = TRUE)
#' roads <- terra::vect(matrix(c(0, 1, 2, 1), ncol = 2, byrow = TRUE),
#'   type = "lines", crs = "EPSG:3857")
#' has_errors(diagnose_evac_model(hazard, roads, dem))
#' @export
has_errors <- function(x, ...) {
  UseMethod("has_errors")
}

#' @export
has_errors.evac_diagnostics <- function(x, ...) {
  any(x$issues$severity == "error")
}
