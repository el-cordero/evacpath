test_that("diagnose_evac_model flags missing CRS values", {
  dem <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2, vals = 1)
  hazard <- terra::as.polygons(dem, dissolve = TRUE)
  roads <- terra::vect(matrix(c(0, 1, 2, 1), ncol = 2, byrow = TRUE), type = "lines")

  diagnostics <- diagnose_evac_model(hazard, roads, dem, check_reachability = FALSE)

  expect_s3_class(diagnostics, "evac_diagnostics")
  expect_true(any(grepl("missing a coordinate reference system", diagnostics$issues$message)))
  expect_true(has_errors(diagnostics))
})

test_that("diagnose_evac_model flags empty roads", {
  x <- tiny_evac_inputs()
  diagnostics <- diagnose_evac_model(
    x$hazard,
    terra::vect(),
    x$dem,
    check_reachability = FALSE
  )

  expect_true(any(diagnostics$issues$message == "`roads` is empty."))
})

test_that("diagnose_evac_model flags origins outside the hazard zone", {
  x <- tiny_evac_inputs()
  origins <- terra::vect(
    data.frame(x = c(2, 6.5), y = c(3.5, 3.5)),
    geom = c("x", "y"),
    crs = "EPSG:3857"
  )

  diagnostics <- diagnose_evac_model(
    x$hazard,
    x$roads,
    x$dem,
    origins = origins,
    check_reachability = FALSE
  )

  expect_true(any(diagnostics$issues$message == "Some origins fall outside `hazard_zone`."))
  expect_equal(nrow(diagnostics$diagnostic_layers$origins_outside_hazard), 1)
})

test_that("diagnose_evac_model flags DEMs that do not overlap the hazard zone", {
  x <- tiny_evac_inputs()
  remote_dem <- terra::rast(
    nrows = 2, ncols = 2, xmin = 100, xmax = 102, ymin = 100, ymax = 102,
    vals = 1, crs = "EPSG:3857"
  )

  diagnostics <- diagnose_evac_model(
    x$hazard,
    x$roads,
    remote_dem,
    check_reachability = FALSE
  )

  expect_true(any(diagnostics$issues$message == "`dem` does not overlap `hazard_zone`."))
})

test_that("diagnostics print cleanly", {
  x <- tiny_evac_inputs()
  diagnostics <- diagnose_evac_model(x$hazard, x$roads, x$dem, check_reachability = FALSE)

  expect_output(print(diagnostics), "<evac_diagnostics>")
})
