# Create an evacuation grid

Creates polygon grid cells over a hazard/evacuation zone and masks the
grid to the zone. The resulting cells can be intersected with buffered
roads to create road-based origin points.

## Usage

``` r
make_evac_grid(hazard_zone, resolution)
```

## Arguments

- hazard_zone:

  Hazard/evacuation zone as `SpatVector`, `SpatRaster`, or file path.

- resolution:

  Grid cell resolution in map units. Use meters when data are in a
  projected CRS. Can be length 1 or 2.

## Value

A polygon `SpatVector` grid clipped/masked to the hazard zone.

## Examples

``` r
r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
  vals = 1, crs = "EPSG:3857")
zone <- terra::as.polygons(r, dissolve = TRUE)
make_evac_grid(zone, resolution = 1)
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 16, 0  (geometries, attributes)
#> extent      : 0, 4, 0, 4  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
```
