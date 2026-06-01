test_that("map_evac_bottlenecks creates density layers from sf routes", {
  template <- terra::rast(
    nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
    vals = 1, crs = "EPSG:3857"
  )
  routes <- tiny_sf_routes()

  bottlenecks <- map_evac_bottlenecks(
    routes = routes,
    template = template,
    quantile_threshold = 0.9
  )

  expect_s3_class(bottlenecks, "evac_bottleneck")
  expect_s4_class(bottlenecks$density_raster, "SpatRaster")
  expect_s4_class(bottlenecks$high_density_raster, "SpatRaster")
  expect_true(bottlenecks$threshold_value >= 1)
  expect_equal(bottlenecks$summary$n_routes, 2)
})

test_that("map_evac_bottlenecks supports count thresholds and result extraction", {
  template <- terra::rast(
    nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
    vals = 1, crs = "EPSG:3857"
  )
  routes <- tiny_sf_routes()

  bottlenecks <- map_evac_bottlenecks(
    evac_result = list(routes = routes, dem = template),
    min_count = 2,
    return_polygons = FALSE
  )

  expect_equal(bottlenecks$threshold_value, 2)
  expect_null(bottlenecks$high_density_polygons)
  expect_output(print(bottlenecks), "<evac_bottleneck>")
})

test_that("map_evac_bottlenecks requires routes", {
  expect_error(
    map_evac_bottlenecks(),
    "Supply `routes` or an `evac_result` created with `keep_routes = TRUE`"
  )
})
