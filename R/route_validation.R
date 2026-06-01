.validate_sf_lines <- function(x, name) {
  if (!inherits(x, "sf")) {
    stop("`", name, "` must be an sf line object.", call. = FALSE)
  }
  if (nrow(x) == 0L) {
    stop("`", name, "` is empty.", call. = FALSE)
  }
  if (is.na(sf::st_crs(x))) {
    stop("`", name, "` is missing a coordinate reference system.", call. = FALSE)
  }
  geometry_types <- as.character(sf::st_geometry_type(x, by_geometry = TRUE))
  if (!all(geometry_types %in% c("LINESTRING", "MULTILINESTRING"))) {
    stop("`", name, "` must contain only LINESTRING or MULTILINESTRING geometries.", call. = FALSE)
  }
  invisible(x)
}

.route_buffer_overlap <- function(modeled, reference, buffer_m) {
  modeled_length <- as.numeric(sf::st_length(modeled))
  if (!is.finite(modeled_length) || modeled_length <= 0) {
    return(NA_real_)
  }
  reference_buffer <- sf::st_buffer(reference, dist = buffer_m)
  inside <- suppressWarnings(sf::st_intersection(modeled, reference_buffer))
  if (nrow(inside) == 0L) {
    return(0)
  }
  min(100, sum(as.numeric(sf::st_length(inside))) / modeled_length * 100)
}

.route_hausdorff <- function(modeled, reference) {
  as.numeric(sf::st_distance(modeled, reference, which = "Hausdorff"))[1]
}

.route_pdi <- function(modeled, reference) {
  if (!"PDI_validation" %in% getNamespaceExports("leastcostpath")) {
    stop("leastcostpath::PDI_validation() is unavailable.")
  }
  pdi <- leastcostpath::PDI_validation(lcp = modeled, comparison = reference)
  as.numeric(pdi$pdi[1])
}

#' Validate modeled evacuation routes
#'
#' Compares modeled routes with official, observed, collaborator-provided, or
#' manually digitized reference routes. Buffer overlap and Hausdorff-distance
#' comparisons are calculated with `sf`. Path deviation index comparisons use
#' [leastcostpath::PDI_validation()] when available and compatible with the
#' supplied routes.
#'
#' @param modeled_routes An `sf` LINESTRING or MULTILINESTRING object.
#' @param reference_routes An `sf` LINESTRING or MULTILINESTRING object.
#' @param method Comparison method: `"pdi"`, `"buffer_overlap"`, `"hausdorff"`,
#'   or `"all"`.
#' @param buffer_m Buffer distance in projected coordinate reference system
#'   units, typically meters.
#' @param by Optional column name used to match modeled and reference routes.
#'   When `NULL`, each modeled route is matched to its nearest reference route.
#' @param ... Reserved for future extensions.
#' @return An `evac_route_validation` list with route-level `metrics`,
#'   `matched_routes`, requested `method`, `buffer_m`, and `summary`.
#' @examples
#' modeled <- sf::st_sf(
#'   id = "route_a",
#'   geometry = sf::st_sfc(
#'     sf::st_linestring(matrix(c(0, 0, 100, 0), ncol = 2, byrow = TRUE)),
#'     crs = 3857
#'   )
#' )
#' reference <- sf::st_sf(
#'   id = "route_a",
#'   geometry = sf::st_sfc(
#'     sf::st_linestring(matrix(c(0, 5, 100, 5), ncol = 2, byrow = TRUE)),
#'     crs = 3857
#'   )
#' )
#' validate_evac_routes(modeled, reference, method = "buffer_overlap", buffer_m = 10)
#' @export
validate_evac_routes <- function(
  modeled_routes,
  reference_routes,
  method = c("pdi", "buffer_overlap", "hausdorff", "all"),
  buffer_m = 25,
  by = NULL,
  ...
) {
  method <- match.arg(method)
  .validate_sf_lines(modeled_routes, "modeled_routes")
  .validate_sf_lines(reference_routes, "reference_routes")

  if (sf::st_crs(modeled_routes) != sf::st_crs(reference_routes)) {
    stop("`modeled_routes` and `reference_routes` must use the same coordinate reference system.", call. = FALSE)
  }
  if (sf::st_is_longlat(modeled_routes)) {
    stop("Route validation requires a projected coordinate reference system.", call. = FALSE)
  }
  if (!is.numeric(buffer_m) || length(buffer_m) != 1L ||
      is.na(buffer_m) || !is.finite(buffer_m) || buffer_m <= 0) {
    stop("`buffer_m` must be a single positive numeric value.", call. = FALSE)
  }
  if (!is.null(by) &&
      (!is.character(by) || length(by) != 1L || !nzchar(by) ||
        !by %in% names(modeled_routes) || !by %in% names(reference_routes))) {
    stop("`by` must name a column present in both route objects.", call. = FALSE)
  }

  reference_index <- if (is.null(by)) {
    sf::st_nearest_feature(modeled_routes, reference_routes)
  } else {
    match(modeled_routes[[by]], reference_routes[[by]])
  }

  calculate_buffer <- method %in% c("buffer_overlap", "all")
  calculate_hausdorff <- method %in% c("hausdorff", "all")
  calculate_pdi <- method %in% c("pdi", "all")
  pdi_failed <- FALSE

  metrics <- lapply(
    seq_len(nrow(modeled_routes)),
    function(i) {
      j <- reference_index[i]
      if (is.na(j)) {
        return(data.frame(
          modeled_index = i,
          reference_index = NA_integer_,
          buffer_overlap_pct = NA_real_,
          hausdorff_distance = NA_real_,
          pdi = NA_real_
        ))
      }

      modeled <- modeled_routes[i, ]
      reference <- reference_routes[j, ]
      pdi <- NA_real_
      if (calculate_pdi) {
        pdi <- tryCatch(
          .route_pdi(modeled, reference),
          error = function(e) {
            pdi_failed <<- TRUE
            NA_real_
          }
        )
      }

      data.frame(
        modeled_index = i,
        reference_index = j,
        buffer_overlap_pct = if (calculate_buffer) {
          .route_buffer_overlap(modeled, reference, buffer_m = buffer_m)
        } else {
          NA_real_
        },
        hausdorff_distance = if (calculate_hausdorff) {
          .route_hausdorff(modeled, reference)
        } else {
          NA_real_
        },
        pdi = pdi
      )
    }
  )
  metrics <- do.call(rbind, metrics)

  if (isTRUE(pdi_failed)) {
    warning(
      "Path deviation index could not be calculated for one or more route pairs; other requested metrics were retained.",
      call. = FALSE
    )
  }

  matched_routes <- modeled_routes
  matched_routes$reference_index <- reference_index
  if (!is.null(by)) {
    matched_routes$reference_id <- modeled_routes[[by]]
  }

  out <- list(
    metrics = metrics,
    matched_routes = matched_routes,
    method = method,
    buffer_m = buffer_m,
    summary = data.frame(
      n_modeled = nrow(modeled_routes),
      n_reference = nrow(reference_routes),
      mean_buffer_overlap = if (any(is.finite(metrics$buffer_overlap_pct))) {
        mean(metrics$buffer_overlap_pct, na.rm = TRUE)
      } else {
        NA_real_
      },
      median_buffer_overlap = if (any(is.finite(metrics$buffer_overlap_pct))) {
        stats::median(metrics$buffer_overlap_pct, na.rm = TRUE)
      } else {
        NA_real_
      },
      mean_pdi = if (any(is.finite(metrics$pdi))) mean(metrics$pdi, na.rm = TRUE) else NA_real_,
      median_pdi = if (any(is.finite(metrics$pdi))) stats::median(metrics$pdi, na.rm = TRUE) else NA_real_
    )
  )
  class(out) <- c("evac_route_validation", "list")
  out
}

#' @export
print.evac_route_validation <- function(x, ...) {
  cat("<evac_route_validation>\n")
  cat("Method: ", x$method, "\n", sep = "")
  print(x$summary, row.names = FALSE)
  invisible(x)
}
