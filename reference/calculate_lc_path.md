# Calculate a least-cost path between one origin and one destination

Compatibility wrapper around
[`leastcostpath::create_lcp()`](https://rdrr.io/pkg/leastcostpath/man/create_lcp.html)
that returns `NULL` when a path cannot be created.

## Usage

``` r
calculate_lc_path(cs, origin, destination)
```

## Arguments

- cs:

  A `leastcostpath` conductance surface.

- origin:

  Origin point.

- destination:

  Destination point.

## Value

A least-cost path object or `NULL`.

## Examples

``` r
dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
  vals = 1, crs = "EPSG:3857")
cs <- make_conductance_surface(dem)
#> calculating slope...
#> Applying tobler cost function
origin <- terra::vect(data.frame(x = 0.5, y = 0.5), geom = c("x", "y"), crs = "EPSG:3857")
destination <- terra::vect(data.frame(x = 4.5, y = 4.5), geom = c("x", "y"), crs = "EPSG:3857")
calculate_lc_path(cs, origin, destination)
#> class       : SpatVector
#> geometry    : lines
#> dimensions  : 1, 3  (geometries, attributes)
#> extent      : 0.5, 4.5, 0.5, 4.5  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator
#> names       : costFunction fromCell toCell
#> type        :        <chr>    <num>  <num>
#> values      :       tobler       21      5
```
