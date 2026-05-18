#' evacpath: Least-cost pedestrian evacuation modeling in R
#'
#' `evacpath` provides tools for modeling pedestrian evacuation distance and
#' travel time from hazard zones to safety areas using road-constrained least-cost
#' path analysis.
#'
#' The package is organized as a set of modular functions. Typical workflows use
#' `prepare_tsunami_zones()` to create tsunami-specific hazard and escape zones,
#' `crop_roads_to_inner_extent()` and `make_road_aware_escape_zone()` to prevent
#' false escape points along artificial study-area boundaries while retaining
#' bridge and walkway corridors, `find_escape_points()` to identify candidate
#' exits, `make_conductance_surface()` to build a slope-based conductance surface,
#' and `run_evacpath()` to run the full workflow.
#'
#' @keywords package
"_PACKAGE"
