test_that("clean_roads removes excluded road features", {
  roads <- terra::vect(
    list(
      matrix(c(0, 0, 0, 1), ncol = 2, byrow = TRUE),
      matrix(c(1, 0, 1, 1), ncol = 2, byrow = TRUE)
    ),
    type = "lines",
    crs = "EPSG:3857"
  )
  roads$kind <- c("road", "pier")

  cleaned <- clean_roads(roads, exclude = list(field = "kind", values = "pier"))

  expect_equal(nrow(cleaned), 1)
  expect_equal(terra::values(cleaned)$kind, "road")
})
