tiny_evac_inputs <- function() {
  dem <- terra::rast(
    nrows = 7,
    ncols = 7,
    xmin = 0,
    xmax = 7,
    ymin = 0,
    ymax = 7,
    crs = "EPSG:3857"
  )
  xy <- terra::crds(dem, df = TRUE)
  terra::values(dem) <- 1 + 0.02 * xy$x + 0.01 * xy$y
  hazard <- terra::as.polygons(
    terra::crop(dem, terra::ext(1, 6, 1, 6)),
    dissolve = TRUE
  )
  roads <- terra::vect(
    matrix(c(0, 3.5, 7, 3.5), ncol = 2, byrow = TRUE),
    type = "lines",
    crs = "EPSG:3857"
  )
  list(dem = dem, hazard = hazard, roads = roads)
}

tiny_run_args <- function() {
  x <- tiny_evac_inputs()
  list(
    hazard_zone = x$hazard,
    roads = x$roads,
    dem = x$dem,
    grid_resolution = 1,
    road_buffer_m = 0.2,
    escape_buffer_m = 0.3,
    final_road_buffer_m = 0.2,
    max_origins = 2,
    max_destinations = 2,
    seed = 1
  )
}

tiny_sf_routes <- function() {
  sf::st_sf(
    id = c("a", "b"),
    geometry = sf::st_sfc(
      sf::st_linestring(matrix(c(0.5, 0.5, 4.5, 4.5), ncol = 2, byrow = TRUE)),
      sf::st_linestring(matrix(c(0.5, 4.5, 4.5, 0.5), ncol = 2, byrow = TRUE)),
      crs = 3857
    )
  )
}
