# Read a spatial input

Accepts an existing `terra` object or a file path and returns a
`SpatRaster` or `SpatVector`. Raster-like extensions are read with
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
and vector-like extensions are read with
[`terra::vect()`](https://rspatial.github.io/terra/reference/vect.html).

## Usage

``` r
read_spatial(x)
```

## Arguments

- x:

  A `SpatRaster`, `SpatVector`, or file path.

## Value

A `SpatRaster` or `SpatVector`.

## Examples

``` r
r <- terra::rast(nrows = 2, ncols = 2, vals = 1)
read_spatial(r)
#> class       : SpatRaster
#> size        : 2, 2, 1  (nrow, ncol, nlyr)
#> resolution  : 180, 90  (x, y)
#> extent      : -180, 180, -90, 90  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (CRS84) (OGC:CRS84)
#> source(s)   : memory
#> name        : lyr.1
#> min value   :     1
#> max value   :     1
```
