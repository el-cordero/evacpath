# Create a road-constrained analysis mask

Buffers the road network and candidate escape points, combines those
buffered areas, and dissolves the result. The mask is used to constrain
least-cost movement to the road/pathway network while allowing access
around escape locations.

## Usage

``` r
make_road_mask(
  roads,
  escape_points,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  return_components = FALSE
)
```

## Arguments

- roads:

  Road/pathway network.

- escape_points:

  Candidate escape/safety points.

- road_buffer_m:

  Road buffer distance in map units, typically meters.

- escape_buffer_m:

  Escape-point buffer distance in map units, typically meters.

- return_components:

  Logical. If `TRUE`, return a list with the mask and component buffers.

## Value

A dissolved road mask `SpatVector`, or a list when
`return_components = TRUE`.

## Examples

``` r
roads <- terra::vect(matrix(c(0, 1, 4, 1), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
escape <- terra::vect(data.frame(x = 4, y = 1), geom = c("x", "y"), crs = "EPSG:3857")
make_road_mask(roads, escape, road_buffer_m = 0.1, escape_buffer_m = 0.2)
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 1, 0  (geometries, attributes)
#> extent      : -0.1, 4.2, 0.8, 1.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
```
