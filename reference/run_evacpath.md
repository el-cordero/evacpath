# Run the full evacuation-path modeling workflow

This high-level wrapper runs the core `evacpath` pipeline: read/project
inputs, create an evacuation grid, identify escape/safety points, build
a road mask, create a slope-based conductance surface, calculate minimum
least-cost distance to safety, and create evacuation-time polygons.

## Usage

``` r
run_evacpath(
  hazard_zone,
  roads,
  dem,
  target_crs = NULL,
  region_name = NULL,
  escape_zone = NULL,
  roads_for_escape = NULL,
  escape_roads_inset_x_m = 0,
  escape_roads_inset_y_m = 0,
  road_aware_escape_zone = FALSE,
  escape_zone_road_buffer_m = NULL,
  escape_zone_crop_buffer_m = NULL,
  study_area = NULL,
  road_exclude = NULL,
  grid_resolution = NULL,
  grid_resolution_factor = 5,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  final_road_buffer_m = 3,
  region_buffer_m = 5000,
  dem_resolution = NULL,
  max_origins = NULL,
  max_destinations = NULL,
  seed = 23401,
  walking_speed_mps = 1.22,
  lcp_cost_function = "tobler",
  lcp_neighbours = 16,
  lcp_crit_slope = 12,
  lcp_max_slope = NULL,
  lcp_args = list(),
  clip_mode = c("hazard", "road_hazard", "hazard_plus_roads", "none"),
  progress = FALSE,
  progress_every = 1L,
  lcp_check_locations = FALSE,
  keep_routes = FALSE
)
```

## Arguments

- hazard_zone:

  Hazard/inundation zone as `SpatRaster`, `SpatVector`, or path. This
  should usually be the land-only area where evacuation origins and
  final output surfaces are mapped.

- roads:

  Road/pathway network as `SpatVector` or path.

- dem:

  Elevation raster as `SpatRaster` or path.

- target_crs:

  Optional projected CRS in meters, for example `"EPSG:32748"`.

- region_name:

  Optional region name stored in output polygons.

- escape_zone:

  Optional boundary zone used only to identify escape/safety points. For
  tsunami workflows, pass the land-inundation-plus-water zone from
  [`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)
  here. If `NULL`, `hazard_zone` is used.

- roads_for_escape:

  Optional road/pathway layer used only for escape-point detection. If
  `NULL`, `roads` is used. This is useful when the full road dataset
  extends beyond the reliable hazard-zone study extent.

- escape_roads_inset_x_m:

  Optional x-direction inset applied to `roads_for_escape` before
  escape-point detection. This prevents roads from intersecting
  artificial study-area extent boundaries.

- escape_roads_inset_y_m:

  Optional y-direction inset applied to `roads_for_escape` before
  escape-point detection.

- road_aware_escape_zone:

  Logical. If `TRUE`, buffered `roads_for_escape` are combined with
  `escape_zone` before escape points are generated. This preserves
  bridge, causeway, and walkway corridors over water that can be lost
  when the tsunami layer is split into land and water masks.

- escape_zone_road_buffer_m:

  Road buffer used when `road_aware_escape_zone = TRUE`.

- escape_zone_crop_buffer_m:

  Additional buffer used when `road_aware_escape_zone = TRUE`.

- study_area:

  Optional local study area for limiting escape-point search.

- road_exclude:

  Optional list passed to
  [`clean_roads()`](https://el-cordero.github.io/evacpath/reference/clean_roads.md).

- grid_resolution:

  Evacuation-grid resolution. If `NULL`, calculated from
  `terra::res(dem) * grid_resolution_factor`.

- grid_resolution_factor:

  Multiplier applied to DEM resolution when `grid_resolution = NULL`.

- road_buffer_m:

  Road buffer distance.

- escape_buffer_m:

  Escape-point buffer distance.

- final_road_buffer_m:

  Output clipping buffer around roads.

- region_buffer_m:

  Buffer around `study_area` used when finding escape points.

- dem_resolution:

  Optional DEM resolution used before conductance creation.

- max_origins:

  Optional maximum number of road origin points.

- max_destinations:

  Optional maximum number of escape/safety destination points. This is
  useful for quick tests in regions where roads intersect the hazard
  boundary many times.

- seed:

  Random seed used when `max_origins` or `max_destinations` is supplied.

- walking_speed_mps:

  Walking speed in meters per second. This controls conversion of
  modeled route distances into evacuation times. It does not change
  route geometry.

- lcp_cost_function:

  Character string or function passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).
  This changes conductance and may change route geometry.

- lcp_neighbours:

  Neighbourhood passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).
  Use `4`, `8`, `16`, `32`, `48`, or a custom matrix accepted by
  `leastcostpath`.

- lcp_crit_slope:

  Numeric critical slope passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).

- lcp_max_slope:

  Optional numeric maximum traversable slope passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).

- lcp_args:

  Named list of additional arguments passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html),
  such as `exaggeration`. Explicit `lcp_*` arguments take precedence
  over duplicate entries in this list.

- clip_mode:

  Output clipping mode. The default `"hazard"` creates a continuous
  time-grid polygon surface clipped to the land-only hazard zone. Use
  `"road_hazard"` for the older road-buffer-limited output,
  `"hazard_plus_roads"` to retain both, or `"none"` for unclipped
  Voronoi polygons.

- progress:

  Logical. Print progress while running least-cost paths.

- progress_every:

  Integer. Print progress every `n` origins when `progress = TRUE`.

- lcp_check_locations:

  Logical passed to
  [`leastcostpath::create_lcp()`](https://rdrr.io/pkg/leastcostpath/man/create_lcp.html).
  Default is `FALSE` for speed after projection/cropping checks.

- keep_routes:

  Logical. If `TRUE`, retain the selected least-cost route for each
  reachable origin in `result$routes`. The default is `FALSE` to avoid
  the additional memory cost.

## Value

An `evacpath_result` list containing spatial outputs and parameters.

## Details

For tsunami applications, `hazard_zone` and `escape_zone` should often
be different. Use a land-only `hazard_zone` for origins and output
mapping, but use a water-combined `escape_zone` for escape-point
detection so the coastline is not treated as an artificial safety
boundary. The helper
[`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)
creates both objects.

## Examples

``` r
dem <- terra::rast(nrows = 7, ncols = 7, xmin = 0, xmax = 7, ymin = 0, ymax = 7,
  vals = 1, crs = "EPSG:3857")
hazard_raster <- terra::crop(dem, terra::ext(1, 6, 1, 6))
hazard <- terra::as.polygons(hazard_raster, dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 3.5, 7, 3.5), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
result <- run_evacpath(
  hazard_zone = hazard,
  roads = roads,
  dem = dem,
  grid_resolution = 1,
  road_buffer_m = 0.2,
  escape_buffer_m = 0.3,
  final_road_buffer_m = 0.2,
  max_origins = 2,
  max_destinations = 2,
  seed = 1
)
#> calculating slope...
#> Applying tobler cost function
#> 1 least-cost paths could not be calculated from origin to destination as these share the same location
result
#> <evacpath_result>
#> Outputs:
#>   - hazard_zone (land-only output/origin zone)
#>   - escape_zone (base escape zone)
#>   - escape_boundary_zone (road-aware/inset-adjusted boundary used for escape points)
#>   - roads_for_escape
#>   - evac_grid
#>   - escape_points
#>   - road_points
#>   - distance_points
#>   - evac_polygons / time_grid
```
