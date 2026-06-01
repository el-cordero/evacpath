test_that("make_conductance_surface preserves defaults and accepts custom settings", {
  x <- tiny_evac_inputs()

  defaults <- suppressMessages(make_conductance_surface(x$dem))
  neighbours <- suppressMessages(make_conductance_surface(x$dem, lcp_neighbours = 8))
  custom_cost <- function(slope) rep(1, length(slope))
  custom <- suppressMessages(make_conductance_surface(x$dem, lcp_cost_function = custom_cost))

  expect_s3_class(defaults, "conductanceMatrix")
  expect_equal(defaults$neighbours, 16)
  expect_equal(neighbours$neighbours, 8)
  expect_true(is.function(custom$costFunction))
})

test_that("make_conductance_surface validates method and neighbours", {
  x <- tiny_evac_inputs()

  expect_error(
    make_conductance_surface(x$dem, method = "invalid"),
    "`method` must be"
  )
  expect_error(
    make_conductance_surface(x$dem, lcp_neighbours = 3),
    "`lcp_neighbours` must be one of"
  )
})

test_that("run_evacpath remains backward compatible and passes custom LCP settings", {
  args <- tiny_run_args()
  baseline <- suppressMessages(do.call(run_evacpath, args))
  custom <- suppressMessages(do.call(
    run_evacpath,
    c(
      args,
      list(
        lcp_neighbours = 8,
        lcp_max_slope = 45,
        lcp_args = list(exaggeration = TRUE),
        keep_routes = TRUE
      )
    )
  ))

  expect_s3_class(baseline, "evacpath_result")
  expect_null(baseline$routes)
  expect_named(custom, names(baseline))
  expect_equal(custom$parameters$lcp_neighbours, 8)
  expect_equal(custom$parameters$lcp_max_slope, 45)
  expect_true(custom$conductance$exaggeration)
  expect_s3_class(custom$routes, "sf")
})

test_that("explicit run_evacpath LCP settings win over lcp_args", {
  args <- tiny_run_args()
  result <- suppressMessages(do.call(
    run_evacpath,
    c(args, list(lcp_neighbours = 8, lcp_args = list(neighbours = 4)))
  ))

  expect_equal(result$conductance$neighbours, 8)
})

test_that("distance calculation reports empty destinations clearly", {
  x <- tiny_evac_inputs()
  cs <- suppressMessages(make_conductance_surface(x$dem))
  origins <- terra::vect(
    data.frame(x = 0.5, y = 0.5),
    geom = c("x", "y"),
    crs = "EPSG:3857"
  )
  destinations <- origins[FALSE, ]

  expect_error(
    calc_min_distance_to_safety(cs, origins, destinations),
    "Destination points is empty"
  )
})
