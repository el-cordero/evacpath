# Test whether diagnostics contain errors

Test whether diagnostics contain errors

## Usage

``` r
has_errors(x, ...)
```

## Arguments

- x:

  An object returned by
  [`diagnose_evac_model()`](https://el-cordero.github.io/evacpath/reference/diagnose_evac_model.md).

- ...:

  Additional arguments passed to methods.

## Value

Logical value indicating whether diagnostics contain at least one error.

## Examples

``` r
dem <- terra::rast(nrows = 2, ncols = 2, vals = 1, crs = "EPSG:3857")
hazard <- terra::as.polygons(dem, dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 1, 2, 1), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
has_errors(diagnose_evac_model(hazard, roads, dem))
#> [1] FALSE
```
