test_that("road origins are kept inside the hazard zone", {
  r <- terra::rast(
    nrows = 4,
    ncols = 4,
    xmin = 0,
    xmax = 4,
    ymin = 0,
    ymax = 4,
    vals = 1,
    crs = "EPSG:3857"
  )
  hazard <- terra::as.polygons(terra::crop(r, terra::ext(0, 4, 0, 2)), dissolve = TRUE)
  grid <- make_evac_grid(hazard, resolution = 1)
  roads <- terra::vect(
    matrix(c(-1, 1.95, 5, 1.95), ncol = 2, byrow = TRUE),
    type = "lines",
    crs = "EPSG:3857"
  )
  roads_buffer <- terra::buffer(roads, 0.2)

  origins <- make_road_origins(grid, roads_buffer, hazard_zone = hazard)

  expect_gt(nrow(origins), 0)
  expect_true(all(terra::relate(origins, hazard, "intersects")))
})
