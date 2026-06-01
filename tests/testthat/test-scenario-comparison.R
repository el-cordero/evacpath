test_that("compare_evac_scenarios requires named scenarios", {
  expect_error(
    compare_evac_scenarios(list(list(walking_speed_mps = 1))),
    "`scenarios` must be a non-empty named list"
  )
})

test_that("compare_evac_scenarios combines summaries and spatial outputs", {
  args <- tiny_run_args()
  comparison <- suppressMessages(do.call(
    compare_evac_scenarios,
    c(
      list(
        scenarios = list(
          baseline = list(walking_speed_mps = 1.22),
          slower = list(walking_speed_mps = 0.75)
        )
      ),
      args
    )
  ))

  expect_s3_class(comparison, "evac_scenario_comparison")
  expect_equal(comparison$summary$scenario, c("baseline", "slower"))
  expect_s3_class(comparison$distance_points, "sf")
  expect_s3_class(comparison$time_polygons, "sf")
  expect_setequal(unique(comparison$distance_points$scenario), c("baseline", "slower"))
  expect_setequal(unique(comparison$time_polygons$scenario), c("baseline", "slower"))
  expect_gt(comparison$summary$median_evac_time[2], comparison$summary$median_evac_time[1])
})

test_that("missing scenario metrics do not crash summary extraction", {
  summary <- evacpath:::extract_evac_summary(
    list(parameters = list(lcp_neighbours = 8)),
    scenario = "incomplete"
  )

  expect_equal(summary$scenario, "incomplete")
  expect_true(is.na(summary$median_evac_time))
  expect_true(is.na(summary$n_origins))
})

test_that("one failed scenario does not discard successful scenarios", {
  args <- tiny_run_args()
  comparison <- suppressMessages(do.call(
    compare_evac_scenarios,
    c(
      list(
        scenarios = list(
          baseline = list(),
          invalid = list(lcp_neighbours = 3)
        ),
        quiet = TRUE
      ),
      args
    )
  ))

  expect_s3_class(comparison$results$baseline, "evacpath_result")
  expect_match(comparison$results$invalid$error, "`lcp_neighbours` must be one of")
  expect_equal(comparison$summary$scenario, c("baseline", "invalid"))
  expect_true(is.na(comparison$summary$median_evac_time[2]))
})

test_that("scenario comparison prints cleanly", {
  args <- tiny_run_args()
  comparison <- suppressMessages(do.call(
    compare_evac_scenarios,
    c(list(scenarios = list(baseline = list()), quiet = TRUE), args)
  ))

  expect_output(print(comparison), "<evac_scenario_comparison>")
})
