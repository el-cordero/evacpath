# Compare evacuation scenarios

Runs
[`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
repeatedly across named scenario overrides and returns scenario
summaries with combined spatial outputs when those layers are available.

## Usage

``` r
compare_evac_scenarios(
  scenarios,
  ...,
  scenario_id_col = "scenario",
  keep_routes = FALSE,
  quiet = FALSE
)
```

## Arguments

- scenarios:

  Named list. Each element is a named list of arguments that override
  shared arguments passed through `...`.

- ...:

  Shared arguments passed to
  [`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md).

- scenario_id_col:

  Name of the scenario identifier column added to combined spatial
  outputs.

- keep_routes:

  Logical. Retain selected least-cost routes in each scenario result.
  Use `TRUE` when route-density analysis is needed.

- quiet:

  Logical. If `TRUE`, suppress warnings when a scenario fails or summary
  metrics are unavailable.

## Value

An `evac_scenario_comparison` list with `results`, `summary`,
`distance_points`, `time_polygons`, and `metadata`.

## Examples

``` r
dem <- terra::rast(nrows = 7, ncols = 7, xmin = 0, xmax = 7, ymin = 0, ymax = 7,
  vals = 1, crs = "EPSG:3857")
hazard <- terra::as.polygons(terra::crop(dem, terra::ext(1, 6, 1, 6)), dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 3.5, 7, 3.5), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
comparison <- compare_evac_scenarios(
  scenarios = list(baseline = list(), slower = list(walking_speed_mps = 0.9)),
  hazard_zone = hazard, roads = roads, dem = dem, grid_resolution = 1,
  road_buffer_m = 0.2, escape_buffer_m = 0.3, final_road_buffer_m = 0.2,
  max_origins = 1, max_destinations = 2, seed = 1
)
#> calculating slope...
#> Applying tobler cost function
#> 1 least-cost paths could not be calculated from origin to destination as these share the same location
#> calculating slope...
#> Applying tobler cost function
#> 1 least-cost paths could not be calculated from origin to destination as these share the same location
comparison$summary
#>   scenario n_origins n_destinations min_evac_time median_evac_time
#> 1 baseline         1              2    0.06830601       0.06830601
#> 2   slower         1              2    0.09259259       0.09259259
#>   mean_evac_time max_evac_time pct_over_10_min pct_over_15_min pct_over_20_min
#> 1     0.06830601    0.06830601               0               0               0
#> 2     0.09259259    0.09259259               0               0               0
#>   pct_over_30_min lcp_cost_function lcp_neighbours walking_speed_mps
#> 1               0            tobler             16              1.22
#> 2               0            tobler             16              0.90
```
