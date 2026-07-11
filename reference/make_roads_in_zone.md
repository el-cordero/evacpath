# Create a buffered road area inside an inundation or analysis zone

Mirrors the original script logic where roads were buffered, optionally
buffered again for tolerance, cropped to the inundation zone, and then
combined with the zone. This is useful for quality assurance and quality
control and for reproducing the earlier road-plus-inundation analysis
area.

## Usage

``` r
make_roads_in_zone(
  roads,
  zone,
  road_buffer_m = 2,
  crop_buffer_m = 3,
  include_zone = TRUE
)
```

## Arguments

- roads:

  Road/pathway network.

- zone:

  Polygon/raster zone used to crop buffered roads.

- road_buffer_m:

  First road buffer distance.

- crop_buffer_m:

  Optional second buffer applied before cropping.

- include_zone:

  Logical. If `TRUE`, combine the cropped road buffer with `zone` and
  dissolve the result.

## Value

A `SpatVector`.

## Examples

``` r
r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
  vals = 1, crs = "EPSG:3857")
zone <- terra::as.polygons(r, dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 2, 4, 2), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
make_roads_in_zone(roads, zone, road_buffer_m = 0.1)
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 1, 0  (geometries, attributes)
#> extent      : 0, 4, 0, 4  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
```
