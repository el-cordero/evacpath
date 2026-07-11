# Add buffered road corridors to an escape-boundary zone

Creates a road-aware escape zone by combining a base escape zone with
buffered road/pathway corridors. This is useful for tsunami workflows in
coastal cities where bridges, causeways, or other walkways over water
can be lost when the inundation layer is split into land and water
masks. The resulting object can be passed to
[`find_escape_points()`](https://el-cordero.github.io/evacpath/reference/find_escape_points.md)
so escape/safety points are generated from a boundary that includes
relevant road corridors as well as the tsunami zone.

## Usage

``` r
make_road_aware_escape_zone(
  escape_zone,
  roads,
  road_buffer_m = 2,
  crop_buffer_m = 3,
  include_base_zone = TRUE
)
```

## Arguments

- escape_zone:

  Base escape-boundary zone, usually the land-inundation-plus- water
  zone from
  [`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md).

- roads:

  Road/pathway network used to create the road-aware corridor.

- road_buffer_m:

  First road buffer distance in map units.

- crop_buffer_m:

  Optional second buffer applied before cropping/combining.

- include_base_zone:

  Logical. If `TRUE`, combine the buffered roads with the original
  `escape_zone`. If `FALSE`, only the buffered road corridor is
  returned.

## Value

A dissolved `SpatVector` escape-boundary zone.

## Examples

``` r
r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
  vals = 1, crs = "EPSG:3857")
zone <- terra::as.polygons(r, dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 2, 4, 2), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
make_road_aware_escape_zone(zone, roads, road_buffer_m = 0.1)
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 1, 0  (geometries, attributes)
#> extent      : 0, 4, 0, 4  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
```
