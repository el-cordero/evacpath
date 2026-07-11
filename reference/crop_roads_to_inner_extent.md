# Crop roads to an inset extent before escape-point detection

Crops a road/pathway layer to a slightly reduced bounding box around a
zone. This is useful before escape-point detection because roads
extending beyond the study-area coverage can intersect artificial raster
or polygon extent edges and create false escape/safety points.

## Usage

``` r
crop_roads_to_inner_extent(roads, zone, inset_x_m = 250, inset_y_m = 250)
```

## Arguments

- roads:

  Road/pathway network as a `SpatVector` or file path.

- zone:

  Zone used to define the outer extent. Can be a `SpatVector`,
  `SpatRaster`, or file path.

- inset_x_m:

  Numeric. Distance to inset the minimum and maximum x boundaries, in
  map units. Use meters when the data are projected.

- inset_y_m:

  Numeric. Distance to inset the minimum and maximum y boundaries, in
  map units. Use meters when the data are projected.

## Value

A cropped road/pathway `SpatVector`.

## Examples

``` r
r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4,
  vals = 1, crs = "EPSG:3857")
zone <- terra::as.polygons(r, dissolve = TRUE)
roads <- terra::vect(matrix(c(-1, 2, 5, 2), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
crop_roads_to_inner_extent(roads, zone, inset_x_m = 0.5, inset_y_m = 0)
#> class       : SpatVector
#> geometry    : lines
#> dimensions  : 1, 0  (geometries, attributes)
#> extent      : 0.5, 3.5, 2, 2  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator (EPSG:3857)
```
