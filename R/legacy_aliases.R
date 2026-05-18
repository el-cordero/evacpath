# Backward-compatible aliases for the original paper scripts -----------------

#' Backward-compatible alias for `make_evac_grid()`
#'
#' @param area.evac Evacuation/hazard zone.
#' @param res Grid resolution.
#' @return A polygon `SpatVector` grid.
#' @export
evacuation_grid <- function(area.evac, res) {
  make_evac_grid(hazard_zone = area.evac, resolution = res)
}

#' Backward-compatible alias for `make_region_area()`
#'
#' @param area.evac Full evacuation/hazard zone.
#' @param area.study Study area.
#' @return A polygon `SpatVector`.
#' @export
region_area <- function(area.evac, area.study) {
  make_region_area(hazard_zone = area.evac, study_area = area.study, buffer_m = 5000)
}

#' Backward-compatible alias for `find_escape_points()`
#'
#' @param area.evac Evacuation/hazard zone.
#' @param network Road/pathway network.
#' @param area.study Optional study area.
#' @return A point `SpatVector`.
#' @export
escape_points <- function(area.evac, network, area.study = NULL) {
  find_escape_points(hazard_zone = area.evac, roads = network, study_area = area.study)
}
