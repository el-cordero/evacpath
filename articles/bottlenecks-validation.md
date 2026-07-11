# Bottlenecks and route validation

Route-density analysis can identify **modeled high-use corridors**. It
does not measure observed pedestrian traffic unless modeled routes are
compared with independent route or movement data.

## Retain modeled routes

Route geometries are optional because they can increase memory use.
Request them when the result will be used for corridor analysis.

``` r

result <- run_evacpath(
  hazard_zone = hazard_zone,
  roads = roads,
  dem = dem,
  target_crs = "EPSG:32748",
  keep_routes = TRUE
)
```

## Map modeled high-use corridors

``` r

bottlenecks <- map_evac_bottlenecks(
  evac_result = result,
  quantile_threshold = 0.9
)

bottlenecks$summary
bottlenecks$high_density_polygons
```

![Modeled high-use corridors from the compact packaged
example.](../reference/figures/pkgdown-example-corridors.png)

Modeled high-use corridors from the compact packaged example.

| Output | Purpose |
|:---|:---|
| density_raster | Count of modeled route overlap on the selected raster grid. |
| high_density_raster | Cells meeting the selected density threshold. |
| high_density_polygons | Optional polygons outlining selected high-density cells. |
| summary | Route count, density threshold, and high-density area metrics. |

The threshold selects high-density raster cells from route overlap.
Inspect the template resolution, threshold choice, and underlying route
set before describing a corridor as a planning bottleneck.

## Compare with reference routes

[`validate_evac_routes()`](https://el-cordero.github.io/evacpath/reference/validate_evac_routes.md)
accepts `sf` line layers. It can match by an ID column or compare each
modeled route with the nearest reference route.

``` r

validation <- validate_evac_routes(
  modeled_routes = modeled_routes,
  reference_routes = reference_routes,
  method = "all",
  buffer_m = 25,
  by = "route_id"
)

validation$summary
```

Buffer overlap measures how much modeled line length falls within a
reference route buffer. Hausdorff distance measures geometric
separation. Path deviation index is attempted when the route pair is
compatible with `leastcostpath`.
