#' Calculate a least-cost path between one origin and one destination
#'
#' Compatibility wrapper around [leastcostpath::create_lcp()] that returns `NULL`
#' when a path cannot be created.
#'
#' @param cs A `leastcostpath` conductance surface.
#' @param origin Origin point.
#' @param destination Destination point.
#' @return A least-cost path object or `NULL`.
#' @export
calculate_lc_path <- function(cs, origin, destination) {
  tryCatch(
    leastcostpath::create_lcp(
      x = cs,
      origin = origin,
      destination = destination,
      check_locations = TRUE
    ),
    error = function(e) NULL
  )
}

#' Calculate the minimum path distance from a list of least-cost paths
#'
#' @param lc_paths_list A list of least-cost path line vectors.
#' @return Minimum non-zero, finite path distance.
#' @export
calculate_min_dist <- function(lc_paths_list) {
  lc_paths <- terra::vect(lc_paths_list)
  d <- terra::perim(lc_paths)
  d <- d[is.finite(d) & d != 0]

  if (length(d) == 0L) {
    return(Inf)
  }

  min(d)
}

#' Calculate minimum least-cost distance from origins to safety
#'
#' For each origin point, calculates least-cost paths to all candidate safety
#' points and stores the shortest finite path distance. Destination points are
#' appended to the output with distance equal to zero.
#'
#' @param cs A `leastcostpath` conductance surface.
#' @param origins Origin points.
#' @param destinations Escape/safety destination points.
#' @param include_destinations Logical. Add destination points with distance = 0.
#' @param progress Logical. Print simple progress messages.
#' @param progress_every Integer. Print progress every `n` origins when `progress = TRUE`.
#' @param check_locations Logical passed to `leastcostpath::create_lcp()`. The default
#'   is `FALSE` for speed after inputs have already been projected and cropped.
#' @return A point `SpatVector` with columns `distance` and `type`.
#' @export
calc_min_distance_to_safety <- function(
  cs,
  origins,
  destinations,
  include_destinations = TRUE,
  progress = FALSE,
  progress_every = 1L,
  check_locations = FALSE
) {
  origins <- read_spatial(origins)
  destinations <- read_spatial(destinations)

  cs_rast <- leastcostpath::rasterise(cs)
  origins <- terra::project(origins, terra::crs(cs_rast))
  destinations <- terra::project(destinations, terra::crs(cs_rast))
  destinations <- terra::crop(destinations, cs_rast, ext = TRUE)

  .stop_empty(origins, "Origin points")
  .stop_empty(destinations, "Destination points")

  progress_every <- as.integer(progress_every)
  if (is.na(progress_every) || progress_every < 1L) {
    progress_every <- 1L
  }

  if (isTRUE(progress)) {
    message("Calculating least-cost distance for ", nrow(origins),
            " origins and ", nrow(destinations), " destinations.")
    message("Conductance raster: ", paste(terra::res(cs_rast), collapse = " x "),
            " map units; ", terra::ncell(cs_rast), " cells.")
  }

  out <- vector("list", nrow(origins))

  for (i in seq_len(nrow(origins))) {
    if (isTRUE(progress) && (i %% progress_every == 0L || i == 1L || i == nrow(origins))) {
      message("Processing origin ", i, " of ", nrow(origins))
    }

    paths <- tryCatch(
      leastcostpath::create_lcp(
        x = cs,
        origin = origins[i, ],
        destination = destinations,
        check_locations = check_locations
      ),
      error = function(e) NULL
    )

    if (is.null(paths)) {
      next
    }

    d <- terra::perim(paths)
    d <- d[is.finite(d) & d != 0]

    if (length(d) == 0L) {
      next
    }

    xy <- terra::crds(origins[i, ], df = TRUE)[1, c("x", "y")]
    out[[i]] <- data.frame(
      x = xy$x,
      y = xy$y,
      distance = min(d),
      type = "road"
    )
  }

  out <- do.call(rbind, out)

  if (is.null(out) || nrow(out) == 0L) {
    warning("No finite least-cost paths were found from origins to destinations.", call. = FALSE)
    out <- data.frame(x = numeric(), y = numeric(), distance = numeric(), type = character())
  }

  if (isTRUE(include_destinations)) {
    dest_xy <- terra::crds(destinations, df = TRUE)
    dest_xy <- dest_xy[, c("x", "y"), drop = FALSE]
    dest_out <- data.frame(
      x = dest_xy$x,
      y = dest_xy$y,
      distance = 0,
      type = "escape"
    )
    out <- rbind(out, dest_out)
  }

  terra::vect(out, geom = c("x", "y"), crs = terra::crs(origins))
}

#' Convert distance to evacuation time
#'
#' @param distance_m Distance in meters.
#' @param walking_speed_mps Walking speed in meters per second. The paper-style
#'   default is 1.22 m/s, but this should be changed for local planning scenarios.
#' @param units Output units: `"minutes"`, `"seconds"`, or `"hours"`.
#' @return Numeric vector of evacuation times.
#' @export
calc_evac_time <- function(distance_m, walking_speed_mps = 1.22, units = "minutes") {
  units <- match.arg(units, choices = c("minutes", "seconds", "hours"))

  if (walking_speed_mps <= 0) {
    stop("`walking_speed_mps` must be greater than zero.", call. = FALSE)
  }

  seconds <- distance_m / walking_speed_mps

  switch(
    units,
    seconds = seconds,
    minutes = seconds / 60,
    hours = seconds / 3600
  )
}

#' Create evacuation-distance and evacuation-time polygons
#'
#' Creates Voronoi polygons from least-cost distance points, converts distance to
#' travel time, and optionally clips the output to an inundated road/study mask.
#'
#' @param distance_points Point output from `calc_min_distance_to_safety()`.
#' @param clip_area Optional polygon used to crop the Voronoi output.
#' @param walking_speed_mps Walking speed in meters per second.
#' @param region_name Optional region/municipality name stored in the output.
#' @param distance_col Name of the output distance column.
#' @param time_col Name of the output time column.
#' @return A polygon `SpatVector`.
#' @export
make_evac_polygons <- function(
  distance_points,
  clip_area = NULL,
  walking_speed_mps = 1.22,
  region_name = NULL,
  distance_col = "DistToSafety",
  time_col = "EvacTimeAvg"
) {
  distance_points <- read_spatial(distance_points)

  if (!"distance" %in% names(distance_points)) {
    stop("`distance_points` must contain a `distance` column.", call. = FALSE)
  }

  v <- terra::voronoi(distance_points)
  v[[time_col]] <- calc_evac_time(as.numeric(v$distance), walking_speed_mps, units = "minutes")
  v[[distance_col]] <- as.numeric(v$distance)

  if (!is.null(region_name)) {
    v$Region <- region_name
  }

  keep <- c(if (!is.null(region_name)) "Region", distance_col, time_col)
  v <- v[, keep]

  if (!is.null(clip_area)) {
    clip_area <- read_spatial(clip_area)
    v <- terra::crop(v, clip_area)
  }

  v
}
