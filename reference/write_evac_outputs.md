# Write evacpath outputs to disk

Writes the main spatial outputs in an `evacpath_result` list to
GeoPackage and GeoTIFF files. Non-spatial objects, including the
conductance surface, are not written.

## Usage

``` r
write_evac_outputs(
  result,
  output_dir,
  prefix = "evacpath",
  overwrite = TRUE,
  include_inputs = FALSE
)
```

## Arguments

- result:

  An object returned by
  [`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md).

- output_dir:

  Output directory.

- prefix:

  Filename prefix.

- overwrite:

  Logical. Overwrite existing files.

- include_inputs:

  Logical. Also write projected input layers.

## Value

A named character vector of written file paths.

## Examples

``` r
dem <- terra::rast(nrows = 7, ncols = 7, xmin = 0, xmax = 7, ymin = 0, ymax = 7,
  vals = 1, crs = "EPSG:3857")
hazard_raster <- terra::crop(dem, terra::ext(1, 6, 1, 6))
hazard <- terra::as.polygons(hazard_raster, dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 3.5, 7, 3.5), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
result <- run_evacpath(
  hazard_zone = hazard,
  roads = roads,
  dem = dem,
  grid_resolution = 1,
  road_buffer_m = 0.2,
  escape_buffer_m = 0.3,
  final_road_buffer_m = 0.2,
  max_origins = 2,
  max_destinations = 2,
  seed = 1
)
#> calculating slope...
#> Applying tobler cost function
#> 1 least-cost paths could not be calculated from origin to destination as these share the same location
out_dir <- file.path(tempdir(), "evacpath-example")
paths <- write_evac_outputs(result, output_dir = out_dir, prefix = "example")
unlink(out_dir, recursive = TRUE)
```
