# Clean a road/pathway network

Removes user-specified features from a road/pathway layer. This is
useful for excluding piers, tunnels, private ways, or other features
that should not be used in pedestrian evacuation modeling.

## Usage

``` r
clean_roads(roads, exclude = NULL, target_crs = NULL)
```

## Arguments

- roads:

  A `SpatVector` or path to a vector layer.

- exclude:

  Optional named list with `field` and `values`, for example
  `list(field = "man_made", values = "pier")`.

- target_crs:

  Optional output CRS.

## Value

A cleaned `SpatVector`.

## Examples

``` r
roads <- terra::vect(
  list(
    matrix(c(0, 0, 0, 1), ncol = 2, byrow = TRUE),
    matrix(c(1, 0, 1, 1), ncol = 2, byrow = TRUE)
  ),
  type = "lines",
  crs = "EPSG:3857"
)
roads$kind <- c("road", "pier")
clean_roads(roads, exclude = list(field = "kind", values = "pier"))
#> class       : SpatVector
#> geometry    : lines
#> dimensions  : 1, 1  (geometries, attributes)
#> extent      : 0, 0, 0, 1  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
#> names       :  kind
#> type        : <chr>
#> values      :  road
```
