# Map modeled evacuation bottlenecks

Creates a route-density raster and identifies high-use modeled
evacuation corridors from supplied least-cost paths or an
[`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
result created with `keep_routes = TRUE`.

## Usage

``` r
map_evac_bottlenecks(
  routes = NULL,
  evac_result = NULL,
  template = NULL,
  quantile_threshold = 0.9,
  min_count = NULL,
  rescale = FALSE,
  return_polygons = TRUE,
  ...
)
```

## Arguments

- routes:

  An `sf` or `SpatVector` line layer of modeled routes.

- evac_result:

  Optional output from
  [`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
  containing retained routes.

- template:

  Optional `SpatRaster` defining the density grid. When omitted, the
  function attempts to infer a template from `evac_result`.

- quantile_threshold:

  Numeric value between `0` and `1`. Used to select high-density route
  cells when `min_count` is `NULL`.

- min_count:

  Optional numeric minimum density count. When supplied, this takes
  precedence over `quantile_threshold`.

- rescale:

  Logical passed to
  [`leastcostpath::create_lcp_density()`](https://rdrr.io/pkg/leastcostpath/man/create_lcp_density.html).

- return_polygons:

  Logical. Convert high-density raster cells to polygons.

- ...:

  Reserved for future extensions.

## Value

An `evac_bottleneck` list with density rasters, optional polygons,
threshold value, and summary.

## Examples

``` r
template <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
  vals = 1, crs = "EPSG:3857")
routes <- sf::st_sf(
  route = c("a", "b"),
  geometry = sf::st_sfc(
    sf::st_linestring(matrix(c(0.5, 0.5, 4.5, 4.5), ncol = 2, byrow = TRUE)),
    sf::st_linestring(matrix(c(0.5, 4.5, 4.5, 0.5), ncol = 2, byrow = TRUE)),
    crs = 3857
  )
)
map_evac_bottlenecks(routes = routes, template = template)
#> <evac_bottleneck>
#>  n_routes max_density threshold_value area_high_density_m2
#>         2           2             1.2                    1
#>  percent_of_route_area_high_density
#>                            11.11111
```
