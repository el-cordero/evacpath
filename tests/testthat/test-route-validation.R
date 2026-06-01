test_that("validate_evac_routes calculates sensible buffer overlap", {
  modeled <- sf::st_sf(
    id = c("a", "b"),
    geometry = sf::st_sfc(
      sf::st_linestring(matrix(c(0, 0, 100, 0), ncol = 2, byrow = TRUE)),
      sf::st_linestring(matrix(c(0, 50, 100, 50), ncol = 2, byrow = TRUE)),
      crs = 3857
    )
  )
  reference <- sf::st_sf(
    id = c("a", "b"),
    geometry = sf::st_sfc(
      sf::st_linestring(matrix(c(0, 5, 100, 5), ncol = 2, byrow = TRUE)),
      sf::st_linestring(matrix(c(0, 100, 100, 100), ncol = 2, byrow = TRUE)),
      crs = 3857
    )
  )

  validation <- validate_evac_routes(
    modeled,
    reference,
    method = "buffer_overlap",
    buffer_m = 10,
    by = "id"
  )

  expect_s3_class(validation, "evac_route_validation")
  expect_equal(validation$metrics$buffer_overlap_pct, c(100, 0))
  expect_equal(validation$matched_routes$reference_id, c("a", "b"))
})

test_that("validate_evac_routes calculates Hausdorff distance and prints", {
  modeled <- tiny_sf_routes()[1, ]
  reference <- tiny_sf_routes()[2, ]

  validation <- validate_evac_routes(modeled, reference, method = "hausdorff")

  expect_true(is.finite(validation$metrics$hausdorff_distance))
  expect_output(print(validation), "<evac_route_validation>")
})

test_that("validate_evac_routes all method retains available metrics if PDI fails", {
  modeled <- sf::st_sf(
    id = "a",
    geometry = sf::st_sfc(
      sf::st_multilinestring(list(
        matrix(c(0, 0, 50, 0), ncol = 2, byrow = TRUE),
        matrix(c(50, 0, 100, 0), ncol = 2, byrow = TRUE)
      )),
      crs = 3857
    )
  )
  reference <- sf::st_sf(
    id = "a",
    geometry = sf::st_sfc(
      sf::st_linestring(matrix(c(0, 5, 100, 5), ncol = 2, byrow = TRUE)),
      crs = 3857
    )
  )

  expect_warning(
    validation <- validate_evac_routes(modeled, reference, method = "all", buffer_m = 10),
    "Path deviation index could not be calculated"
  )
  expect_equal(validation$metrics$buffer_overlap_pct, 100)
  expect_true(is.finite(validation$metrics$hausdorff_distance))
  expect_true(is.na(validation$metrics$pdi))
})

test_that("validate_evac_routes reports invalid combinations", {
  modeled <- tiny_sf_routes()[1, ]
  reference <- tiny_sf_routes()[2, ]

  expect_error(
    validate_evac_routes(modeled, reference, method = "buffer_overlap", by = "missing"),
    "`by` must name a column"
  )
})

test_that("validate_evac_routes reports CRS mismatch clearly", {
  modeled <- tiny_sf_routes()[1, ]
  reference <- sf::st_transform(tiny_sf_routes()[2, ], 32620)

  expect_error(
    validate_evac_routes(modeled, reference, method = "buffer_overlap"),
    "must use the same coordinate reference system"
  )
})
