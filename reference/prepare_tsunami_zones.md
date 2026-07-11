# Prepare separate tsunami zones for escape analysis and visualization

Tsunami evacuation workflows often need two different zone objects. The
land-only inundation zone is the area where road origins and output time
surfaces should be mapped. The escape-boundary zone should combine the
land-only inundation zone with water so that the coastline is not
treated as an artificial escape boundary. This prevents false
escape/safety points along the water-land edge when roads touch or
approach the shoreline.

## Usage

``` r
prepare_tsunami_zones(
  inundation,
  dem,
  target_crs = NULL,
  inundation_threshold = 0,
  land_threshold = 0,
  water_threshold = 0,
  dem_sign_multiplier = 1,
  resample_method = "bilinear",
  as_polygon = TRUE,
  dissolve = TRUE
)
```

## Arguments

- inundation:

  Inundation-depth raster or path to a raster. Cells greater than
  `inundation_threshold` are treated as inundated.

- dem:

  Elevation/topobathymetry raster or path to a raster.

- target_crs:

  Optional projected CRS in meters for returned objects.

- inundation_threshold:

  Numeric threshold used to define inundated cells.

- land_threshold:

  Numeric DEM threshold used to define land. Default is `0`, so land is
  `dem > 0` after applying `dem_sign_multiplier`.

- water_threshold:

  Numeric DEM threshold used to define water. Default is `0`, so water
  is `dem < 0` after applying `dem_sign_multiplier`.

- dem_sign_multiplier:

  Multiplier applied to the DEM before land/water classification. Use
  `-1` when the DEM sign convention is reversed.

- resample_method:

  Method passed to
  [`terra::resample()`](https://rspatial.github.io/terra/reference/resample.html)
  when aligning the inundation raster to the DEM. Use `"bilinear"` for
  depth rasters and `"near"` for categorical rasters.

- as_polygon:

  Logical. If `TRUE`, return polygon zones in addition to rasters.

- dissolve:

  Logical. Dissolve polygon pieces.

## Value

A named list with land-only `hazard_zone`, water-combined `escape_zone`,
and supporting rasters. `hazard_zone` should usually be used for origin
generation, mapping, and output clipping. `escape_zone` should usually
be passed to `run_evacpath(escape_zone = ...)` or
[`find_escape_points()`](https://el-cordero.github.io/evacpath/reference/find_escape_points.md).

## Examples

``` r
dem <- terra::rast(nrows = 6, ncols = 6, xmin = 0, xmax = 6, ymin = 0, ymax = 6,
  crs = "EPSG:3857")
xy <- terra::crds(dem, df = TRUE)
terra::values(dem) <- -1.5 + 0.7 * xy$x + 0.2 * sin(xy$y)
inundation <- dem
terra::values(inundation) <- ifelse(terra::values(dem) > 0 & terra::values(dem) < 2.5, 1, 0)
zones <- prepare_tsunami_zones(inundation, dem, as_polygon = TRUE)
names(zones)
#> [1] "hazard_raster"      "escape_raster"      "land_mask"         
#> [4] "water_mask"         "inundation_aligned" "dem"               
#> [7] "hazard_zone"        "escape_zone"       
```
