test_that("calc_evac_time converts meters to minutes", {
  expect_equal(calc_evac_time(122, walking_speed_mps = 1.22), 100 / 60)
})

test_that("calc_evac_time supports seconds and hours", {
  expect_equal(calc_evac_time(122, walking_speed_mps = 1.22, units = "seconds"), 100)
  expect_equal(calc_evac_time(3600, walking_speed_mps = 1, units = "hours"), 1)
})
