# Prepare a hazard zone from an inundation raster

Converts an inundation raster to a binary hazard-zone raster or polygon
using a threshold. This is intentionally general so users can adapt it
to tsunami, flood, storm-surge, or other hazard layers.

## Usage

``` r
prepare_hazard_zone(
  inundation,
  threshold = 0,
  land_mask = NULL,
  target_crs = NULL,
  as_polygon = TRUE,
  dissolve = TRUE
)
```

## Arguments

- inundation:

  A `SpatRaster` or path to a raster.

- threshold:

  Numeric threshold. Cells greater than `threshold` are treated as
  inside the hazard zone.

- land_mask:

  Optional `SpatRaster` or `SpatVector` used to mask the hazard zone to
  land.

- target_crs:

  Optional output CRS. Use a projected CRS in meters for later distance
  calculations.

- as_polygon:

  Logical. If `TRUE`, return a polygon hazard zone.

- dissolve:

  Logical. If `TRUE`, dissolve polygon pieces.

## Value

A binary `SpatRaster` or polygon `SpatVector`.

## Examples

``` r
r <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5)
terra::values(r) <- c(rep(0, 12), rep(1, 13))
zone <- prepare_hazard_zone(r, threshold = 0, as_polygon = TRUE)
zone
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 1, 0  (geometries, attributes)
#> extent      : 0, 5, 0, 3  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (CRS84) (OGC:CRS84)
```
