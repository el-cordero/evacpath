# Create evacuation-distance and evacuation-time polygons

Creates Voronoi polygons from least-cost distance points, converts
distance to travel time, and optionally clips the output to an inundated
road/study mask.

## Usage

``` r
make_evac_polygons(
  distance_points,
  clip_area = NULL,
  walking_speed_mps = 1.22,
  region_name = NULL,
  distance_col = "DistToSafety",
  time_col = "EvacTimeAvg"
)
```

## Arguments

- distance_points:

  Point output from
  [`calc_min_distance_to_safety()`](https://el-cordero.github.io/evacpath/reference/calc_min_distance_to_safety.md).

- clip_area:

  Optional polygon used to crop the Voronoi output.

- walking_speed_mps:

  Walking speed in meters per second.

- region_name:

  Optional region/municipality name stored in the output.

- distance_col:

  Name of the output distance column.

- time_col:

  Name of the output time column.

## Value

A polygon `SpatVector`.

## Examples

``` r
pts <- terra::vect(
  data.frame(x = c(0, 1, 0, 1), y = c(0, 0, 1, 1), distance = c(0, 5, 10, 15)),
  geom = c("x", "y"),
  crs = "EPSG:3857"
)
clip <- terra::as.polygons(terra::rast(nrows = 2, ncols = 2, xmin = -1, xmax = 2,
  ymin = -1, ymax = 2, vals = 1, crs = "EPSG:3857"), dissolve = TRUE)
make_evac_polygons(pts, clip_area = clip)
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 4, 2  (geometries, attributes)
#> extent      : -1, 2, -1, 2  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
#> names       : DistToSafety EvacTimeAvg
#> type        :        <num>       <num>
#> values      :           15    0.204918
#>                         10    0.136612
#>                          0           0
#>               ...
```
