# Create a broader analysis region around a study area

Dissolves the full hazard zone, buffers a smaller study area, and crops
the full zone to that buffer. This is useful when escape/safety points
outside a municipality or local study area should still be considered.

## Usage

``` r
make_region_area(hazard_zone, study_area, buffer_m = 5000)
```

## Arguments

- hazard_zone:

  Full hazard/evacuation zone.

- study_area:

  Local study area.

- buffer_m:

  Buffer distance in map units, typically meters.

## Value

A polygon `SpatVector` for the broader analysis region.

## Examples

``` r
r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
  vals = 1, crs = "EPSG:3857")
zone <- terra::as.polygons(r, dissolve = TRUE)
study <- terra::as.polygons(terra::crop(r, terra::ext(1, 3, 1, 3)), dissolve = TRUE)
make_region_area(zone, study, buffer_m = 1)
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 1, 0  (geometries, attributes)
#> extent      : 0, 4, 0, 4  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
```
