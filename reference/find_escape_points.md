# Identify escape/safety points where roads cross the hazard-zone boundary

Intersects a road/pathway network with the boundary of the hazard zone
and converts the intersection geometry to points. These points represent
candidate exits from the hazard zone.

## Usage

``` r
find_escape_points(
  hazard_zone,
  roads,
  study_area = NULL,
  region_buffer_m = 5000
)
```

## Arguments

- hazard_zone:

  Hazard/evacuation zone.

- roads:

  Road/pathway network.

- study_area:

  Optional local study area used to crop candidate escape points to a
  broader region around the study area.

- region_buffer_m:

  Buffer distance passed to
  [`make_region_area()`](https://el-cordero.github.io/evacpath/reference/make_region_area.md)
  when `study_area` is supplied.

## Value

A point `SpatVector` of candidate escape/safety points.

## Examples

``` r
r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
  vals = 1, crs = "EPSG:3857")
zone <- terra::as.polygons(r, dissolve = TRUE)
roads <- terra::vect(matrix(c(-1, 2, 5, 2), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
find_escape_points(zone, roads)
#> class       : SpatVector
#> geometry    : points
#> dimensions  : 2, 0  (geometries, attributes)
#> extent      : 0, 4, 2, 2  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
```
