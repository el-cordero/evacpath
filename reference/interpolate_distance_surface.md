# Interpolate a distance surface from least-cost distance points

Uses thin-plate spline interpolation to create a continuous distance
surface. This preserves the original paper-script approach while keeping
interpolation optional. For most package workflows,
[`make_evac_polygons()`](https://el-cordero.github.io/evacpath/reference/make_evac_polygons.md)
is the simpler output.

## Usage

``` r
interpolate_distance_surface(
  distance_points,
  region_area,
  study_area,
  resolution_coarse = 100,
  resolution_fine = 1,
  distance_col = "distance"
)
```

## Arguments

- distance_points:

  Point layer with a distance column.

- region_area:

  Broader analysis region used for interpolation extent.

- study_area:

  Final study area used to crop and mask the output.

- resolution_coarse:

  Coarse interpolation resolution.

- resolution_fine:

  Fine output resolution.

- distance_col:

  Name of distance column in `distance_points`.

## Value

A `SpatRaster` distance surface.

## Examples

``` r
if (requireNamespace("fields", quietly = TRUE)) {
  pts <- terra::vect(
    data.frame(
      x = c(0, 1, 0, 1, 0.5, 1.5),
      y = c(0, 0, 1, 1, 0.5, 1.5),
      distance = c(0, 5, 10, 15, 7, 20)
    ),
    geom = c("x", "y"),
    crs = "EPSG:3857"
  )
  area <- terra::as.polygons(terra::rast(nrows = 2, ncols = 2, xmin = -1, xmax = 2,
    ymin = -1, ymax = 2, vals = 1, crs = "EPSG:3857"), dissolve = TRUE)
  interpolate_distance_surface(pts, area, area, resolution_coarse = 0.5, resolution_fine = 1)
}
#> class       : SpatRaster
#> size        : 3, 3, 1  (nrow, ncol, nlyr)
#> resolution  : 1, 1  (x, y)
#> extent      : -1, 2, -1, 2  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
#> source(s)   : memory
#> name        :      last
#> min value   :  0.331864
#> max value   : 20.422298
```
