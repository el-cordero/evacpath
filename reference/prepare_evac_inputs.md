# Read and project the core evacuation inputs

Read and project the core evacuation inputs

## Usage

``` r
prepare_evac_inputs(
  hazard_zone,
  roads,
  dem,
  target_crs = NULL,
  hazard_as_polygon = TRUE,
  dissolve_hazard = TRUE,
  road_exclude = NULL
)
```

## Arguments

- hazard_zone:

  Hazard/inundation zone as a `SpatRaster`, `SpatVector`, or file path.

- roads:

  Road/pathway network as a `SpatVector` or file path.

- dem:

  Elevation raster as a `SpatRaster` or file path.

- target_crs:

  Optional projected CRS in meters.

- hazard_as_polygon:

  Logical. Convert raster hazard zones to polygons.

- dissolve_hazard:

  Logical. Dissolve hazard polygon pieces.

- road_exclude:

  Optional road exclusion list passed to
  [`clean_roads()`](https://el-cordero.github.io/evacpath/reference/clean_roads.md).

## Value

A named list with `hazard_zone`, `roads`, and `dem`.

## Examples

``` r
dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
  vals = 1, crs = "EPSG:3857")
hazard <- terra::as.polygons(dem, dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 2.5, 5, 2.5), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
inputs <- prepare_evac_inputs(hazard, roads, dem)
names(inputs)
#> [1] "hazard_zone" "roads"       "dem"         "target_crs" 
```
