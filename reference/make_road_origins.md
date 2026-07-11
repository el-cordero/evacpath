# Create road-based origin points inside the evacuation zone

Intersects an evacuation grid with a buffered road network and converts
the resulting road-crossing cell geometry to points.

## Usage

``` r
make_road_origins(
  evac_grid,
  roads_buffer,
  hazard_zone = NULL,
  max_origins = NULL,
  seed = NULL
)
```

## Arguments

- evac_grid:

  Polygon grid from
  [`make_evac_grid()`](https://el-cordero.github.io/evacpath/reference/make_evac_grid.md).

- roads_buffer:

  Buffered road/pathway network.

- hazard_zone:

  Optional hazard-zone polygon used to crop candidate origins after
  intersecting the grid with the road buffer.

- max_origins:

  Optional maximum number of origin points to retain. Useful for large
  regions or exploratory runs.

- seed:

  Random seed used when `max_origins` is supplied.

## Value

A point `SpatVector` of road-based evacuation origins.

## Examples

``` r
r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
  vals = 1, crs = "EPSG:3857")
grid <- make_evac_grid(terra::as.polygons(r, dissolve = TRUE), resolution = 1)
roads <- terra::vect(matrix(c(0, 2, 4, 2), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
roads_buffer <- terra::buffer(roads, 0.2)
make_road_origins(grid, roads_buffer, hazard_zone = terra::as.polygons(r, dissolve = TRUE),
  max_origins = 3, seed = 1)
#> class       : SpatVector
#> geometry    : points
#> dimensions  : 3, 2  (geometries, attributes)
#> extent      : 0.5, 3.5, 1.9, 2.1  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
#> names       : lyr.1_1 lyr.1_2
#> type        :   <int>   <int>
#> values      :       1       1
#>                     1       1
#>                     1       1
```
