# Evacuation workflow: function-by-function diagnostics

This vignette is a diagnostic walkthrough for the example
tsunami-evacuation workflow. It is intentionally more detailed than a
normal user vignette because its purpose is to test every major
`evacpath` function independently before trusting the high-level
[`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
wrapper.

The workflow builds on open-source least-cost path methods for
evacuation planning (Cordero et al. 2025) and uses `leastcostpath` for
least-cost path and movement-potential modeling (Lewis 2023; Lewis
2021).

This example workflow has three important tsunami-specific
complications:

1.  The **land-only inundation zone** is the correct area for evacuation
    origins and final output mapping, but it is not necessarily the
    correct boundary for escape-point detection.
2.  The **water-combined escape zone** prevents the coastline from
    becoming a fake safety boundary.
3.  The **road-aware escape zone** combines buffered roads with the
    escape zone before escape points are generated. This preserves
    bridges, causeways, and walkways over water that can be lost when
    the tsunami layer is split into land and water masks.

The diagnostic workflow therefore uses these separate objects:

``` text
hazard_zone          = land-only tsunami evacuation zone for origins/output
escape_zone          = land-only TEZ + water, used as base escape boundary
roads_for_escape     = roads cropped to an inset study extent
escape_boundary_zone = escape_zone + buffered roads_for_escape
```

## Representative packaged output

The detailed code below is off by default so this guide remains
practical to build and browse. These static results come from the
compact packaged run and show the kinds of spatial and QA/QC outputs to
review before a local rerun.

![Example inputs and candidate safety
exits.](../reference/figures/pkgdown-example-inputs.png)

Example inputs and candidate safety exits.

![Modeled evacuation time to
safety.](../reference/figures/pkgdown-example-time.png)

Modeled evacuation time to safety.

| Modeled output                 | Example value |
|:-------------------------------|--------------:|
| Minimum modeled time (minutes) |          0.31 |
| Median modeled time (minutes)  |         10.09 |
| Mean modeled time (minutes)    |          9.65 |
| Maximum modeled time (minutes) |         22.84 |
| Origins                        |         40.00 |
| Destinations                   |         12.00 |
| Walking speed (m/s)            |          1.22 |

| QA/QC check            | Result      |
|:-----------------------|:------------|
| Errors                 | 0           |
| Warnings               | 1           |
| Informational checks   | 2           |
| Road features          | 193         |
| Sampled origins        | 40          |
| Candidate safety exits | 12          |
| DEM resolution (m)     | 5.12 x 5.12 |

To run the full diagnostic workflow locally:

``` r

rmarkdown::render(
  "vignettes/diagnostic-example.Rmd",
  output_format = rmarkdown::pdf_document(toc = TRUE, number_sections = TRUE),
  output_file = "diagnostic-example.pdf",
  params = list(
    run_diagnostics = TRUE,
    run_lcp = TRUE,
    data_dir = "data-raw",
    target_crs = "EPSG:32748",
    dem_sign_multiplier = 1,
    grid_multiplier = 50,
    dem_multiplier = 50,
    escape_roads_inset_x_m = 50,
    escape_roads_inset_y_m = 50,
    road_aware_escape_zone = TRUE
  )
)
```

For a faster diagnostic that stops before least-cost paths:

``` r

rmarkdown::render(
  "vignettes/diagnostic-example.Rmd",
  output_format = rmarkdown::pdf_document(toc = TRUE, number_sections = TRUE),
  output_file = "diagnostic-example-fast.pdf",
  params = list(
    run_diagnostics = TRUE,
    run_lcp = FALSE,
    data_dir = "data-raw"
  )
)
```

## Setup

``` r

# This loader works both when the package is installed and during local package development.
if (requireNamespace("evacpath", quietly = TRUE)) {
  library(evacpath)
} else if (requireNamespace("devtools", quietly = TRUE) && file.exists("DESCRIPTION")) {
  devtools::load_all(".")
} else if (requireNamespace("devtools", quietly = TRUE) && file.exists(file.path("..", "DESCRIPTION"))) {
  devtools::load_all("..")
} else if (requireNamespace("devtools", quietly = TRUE) && file.exists(file.path("evacpath", "DESCRIPTION"))) {
  devtools::load_all("evacpath")
} else {
  stop("Install evacpath or run this from the package root/parent directory.", call. = FALSE)
}

library(terra)
#> terra 1.9.34

run_diagnostics <- isTRUE(params$run_diagnostics)
run_lcp <- isTRUE(params$run_lcp)

assert_true <- function(x, message) {
  if (!isTRUE(x)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

is_spatvector <- function(x) inherits(x, "SpatVector")
is_spatraster <- function(x) inherits(x, "SpatRaster")

count_features <- function(x) {
  if (inherits(x, "SpatRaster")) return(terra::ncell(x))
  if (inherits(x, "SpatVector")) return(nrow(x))
  NA_integer_
}
```

The diagnostic switches are:

``` r

run_diagnostics
#> [1] FALSE
run_lcp
#> [1] FALSE
```

## Locate example input files

The diagnostic expects these files:

``` text
data-raw/dem.tif
data-raw/rds.gpkg
data-raw/tsunami_inundation_depth.tif
```

The function below searches for them from the package root, the parent
folder, or installed package `extdata`.

``` r

find_input_file <- function(filename, data_dir = params$data_dir) {
  candidate_dirs <- unique(c(
    data_dir,
    file.path("evacpath", data_dir),
    file.path(getwd(), data_dir),
    file.path(getwd(), "evacpath", data_dir),
    system.file("extdata", package = "evacpath")
  ))

  candidate_dirs <- candidate_dirs[nzchar(candidate_dirs)]
  candidates <- file.path(candidate_dirs, filename)
  hits <- candidates[file.exists(candidates)]

  if (length(hits) == 0L) {
    return(NA_character_)
  }

  normalizePath(hits[1])
}

dem_file <- find_input_file("dem.tif")
roads_file <- find_input_file("rds.gpkg")
inundation_file <- find_input_file("tsunami_inundation_depth.tif")

input_files <- data.frame(
  layer = c("DEM", "roads", "inundation depth"),
  file = c(dem_file, roads_file, inundation_file),
  exists = file.exists(c(dem_file, roads_file, inundation_file))
)

input_files
#>              layer
#> 1              DEM
#> 2            roads
#> 3 inundation depth
#>                                                                                     file
#> 1                      /tmp/RtmpVCQpdD/temp_libpath24872e78dceb/evacpath/extdata/dem.tif
#> 2                     /tmp/RtmpVCQpdD/temp_libpath24872e78dceb/evacpath/extdata/rds.gpkg
#> 3 /tmp/RtmpVCQpdD/temp_libpath24872e78dceb/evacpath/extdata/tsunami_inundation_depth.tif
#>   exists
#> 1   TRUE
#> 2   TRUE
#> 3   TRUE

example_data_available <- all(input_files$exists)
example_data_available
#> [1] TRUE
```

If `example_data_available` is `FALSE`, check `params` or use the
packaged files in `inst/extdata/`.

## Read Spatial Inputs

[`read_spatial()`](https://el-cordero.github.io/evacpath/reference/read_spatial.md)
accepts a file path or an existing `terra` object. Raster formats are
read with
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
and vector formats are read with
[`terra::vect()`](https://rspatial.github.io/terra/reference/vect.html).

``` r

dem_raw <- read_spatial(dem_file)
roads_raw <- read_spatial(roads_file)
inundation_raw <- read_spatial(inundation_file)

assert_true(is_spatraster(dem_raw), "DEM was not read as a SpatRaster.")
assert_true(is_spatvector(roads_raw), "Roads were not read as a SpatVector.")
assert_true(is_spatraster(inundation_raw), "Inundation input was not read as a SpatRaster.")

list(
  dem_class = class(dem_raw),
  roads_class = class(roads_raw),
  inundation_class = class(inundation_raw)
)
```

### Raw input diagnostics

Before modeling, inspect CRS, extent, resolution, raster value ranges,
and road attributes.

``` r

cat("DEM CRS:\n", terra::crs(dem_raw), "\n\n")
cat("Roads CRS:\n", terra::crs(roads_raw), "\n\n")
cat("Inundation CRS:\n", terra::crs(inundation_raw), "\n\n")

cat("DEM resolution:\n")
print(terra::res(dem_raw))

cat("Inundation resolution:\n")
print(terra::res(inundation_raw))

cat("DEM cell count:\n")
print(terra::ncell(dem_raw))

cat("Road feature count:\n")
print(nrow(roads_raw))

cat("Road attribute names:\n")
print(names(roads_raw))

cat("DEM range:\n")
print(terra::global(dem_raw, fun = range, na.rm = TRUE))

cat("Inundation range:\n")
print(terra::global(inundation_raw, fun = range, na.rm = TRUE))
```

``` r

oldpar <- par(mfrow = c(1, 2), mar = c(3, 3, 3, 5), las = 1)
plot(dem_raw, main = "Raw DEM")
plot(inundation_raw, main = "Raw inundation depth")
par(oldpar)
```

## Clean Roads

This is where region-specific road filtering belongs. In the packaged
example, piers are excluded because they can create misleading
road-water intersections.

``` r

road_exclude <- NULL
if (!is.null(params$road_exclude_field) && nzchar(params$road_exclude_field)) {
  road_exclude <- list(
    field = params$road_exclude_field,
    values = params$road_exclude_values
  )
}

roads_clean <- clean_roads(
  roads = roads_raw,
  exclude = road_exclude,
  target_crs = params$target_crs
)

assert_true(is_spatvector(roads_clean), "clean_roads() did not return a SpatVector.")
assert_true(nrow(roads_clean) > 0, "clean_roads() returned no roads.")

nrow(roads_raw)
nrow(roads_clean)
```

## Prepare Tsunami Zones

This is the critical tsunami-specific step. The old script created a
land mask, water mask, land-only TEZ, and then a TEZ-plus-water layer.
The package makes that separation explicit.

``` r

zones <- prepare_tsunami_zones(
  inundation = inundation_raw,
  dem = dem_raw,
  target_crs = params$target_crs,
  inundation_threshold = params$inundation_threshold,
  land_threshold = params$land_threshold,
  water_threshold = params$water_threshold,
  dem_sign_multiplier = params$dem_sign_multiplier,
  resample_method = params$resample_method,
  as_polygon = TRUE,
  dissolve = TRUE
)

zones

assert_true(is_spatvector(zones$hazard_zone), "zones$hazard_zone is not a SpatVector.")
assert_true(is_spatvector(zones$escape_zone), "zones$escape_zone is not a SpatVector.")
assert_true(is_spatraster(zones$hazard_raster), "zones$hazard_raster is not a SpatRaster.")
assert_true(is_spatraster(zones$escape_raster), "zones$escape_raster is not a SpatRaster.")

cat("Land-only hazard-zone polygons:", nrow(zones$hazard_zone), "\n")
cat("Water-combined escape-zone polygons:", nrow(zones$escape_zone), "\n")
```

### Check the land/water classification

If land and water are reversed, change `dem_sign_multiplier` from `1` to
`-1` or adjust the thresholds.

``` r

oldpar <- par(mfrow = c(1, 2), mar = c(3, 3, 3, 5), las = 1)
plot(zones$land_mask, col = "grey85", legend = FALSE, main = "DEM-derived land mask")
plot(zones$water_mask, col = "lightskyblue1", legend = FALSE, main = "DEM-derived water mask")
par(oldpar)
```

### Check the two tsunami zones

The land-only zone is for origins and final mapped evacuation time. The
water-combined zone is the base zone for escape-point detection.

``` r

oldpar <- par(mfrow = c(1, 2), mar = c(3, 3, 3, 5), las = 1)
plot(zones$hazard_zone, col = "tomato", border = NA, main = "hazard_zone: land-only TEZ")
plot(zones$escape_zone, col = "grey90", border = NA, main = "escape_zone: TEZ + water")
plot(zones$hazard_zone, add = TRUE, col = "tomato", border = NA)
par(oldpar)
```

## Crop roads to an inner extent before escape-point detection

If the road dataset extends beyond the reliable hazard-zone coverage,
roads can intersect the artificial rectangular study-area boundary.
Those intersections are not real escape points. The fix is to crop the
roads used for escape-point detection to a slightly inset extent. The x
and y insets are controlled separately.

``` r

roads_for_escape <- crop_roads_to_inner_extent(
  roads = roads_clean,
  zone = zones$escape_zone,
  inset_x_m = params$escape_roads_inset_x_m,
  inset_y_m = params$escape_roads_inset_y_m
)

assert_true(is_spatvector(roads_for_escape), "roads_for_escape is not a SpatVector.")
assert_true(nrow(roads_for_escape) > 0, "roads_for_escape has no features.")

cat("Clean roads:", nrow(roads_clean), "\n")
cat("Roads used for escape-point detection:", nrow(roads_for_escape), "\n")
```

``` r

plot(zones$escape_zone, col = "grey92", border = "grey60", main = "Roads cropped to inset extent for escape detection")
plot(roads_clean, add = TRUE, col = adjustcolor("red", alpha.f = 0.25), lwd = 0.35)
plot(roads_for_escape, add = TRUE, col = "black", lwd = 0.45)
legend(
  "topright",
  legend = c("Original cleaned roads", "Roads used for escape detection"),
  col = c(adjustcolor("red", alpha.f = 0.5), "black"),
  lty = 1,
  lwd = 1,
  bty = "n",
  cex = 0.8
)
```

## Combine buffered roads with the escape zone

This is the second major correction. The buffered roads should be
combined with the tsunami escape zone **before** escape points are
generated. Otherwise, bridge, causeway, or walkway segments over water
can be lost because the land and water masks do not always represent the
accessible transportation surface.

The package helper is
[`make_road_aware_escape_zone()`](https://el-cordero.github.io/evacpath/reference/make_road_aware_escape_zone.md).

``` r

escape_boundary_zone <- make_road_aware_escape_zone(
  escape_zone = zones$escape_zone,
  roads = roads_for_escape,
  road_buffer_m = params$road_buffer_m,
  crop_buffer_m = params$final_road_buffer_m,
  include_base_zone = TRUE
)

assert_true(is_spatvector(escape_boundary_zone), "escape_boundary_zone is not a SpatVector.")
assert_true(nrow(escape_boundary_zone) > 0, "escape_boundary_zone has no features.")

nrow(escape_boundary_zone)
```

``` r

plot(escape_boundary_zone, col = "grey90", border = NA, main = "Road-aware escape-boundary zone")
plot(zones$hazard_zone, add = TRUE, col = adjustcolor("tomato", alpha.f = 0.45), border = NA)
plot(roads_for_escape, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.45), lwd = 0.35)
```

## Compare escape-point methods

This section intentionally compares three methods:

1.  Wrong: land-only `hazard_zone`.
2.  Better: TEZ + water `escape_zone`.
3.  Best for this workflow: road-aware escape boundary plus
    inset-cropped roads.

``` r

escape_wrong <- try(
  find_escape_points(
    hazard_zone = zones$hazard_zone,
    roads = roads_clean
  ),
  silent = TRUE
)

escape_water <- find_escape_points(
  hazard_zone = zones$escape_zone,
  roads = roads_for_escape
)

escape_points <- find_escape_points(
  hazard_zone = escape_boundary_zone,
  roads = roads_for_escape
)

comparison <- data.frame(
  method = c(
    "wrong: land-only hazard zone",
    "better: TEZ + water, inset roads",
    "preferred: road-aware escape zone, inset roads"
  ),
  escape_point_count = c(
    if (inherits(escape_wrong, "try-error")) NA_integer_ else nrow(escape_wrong),
    nrow(escape_water),
    nrow(escape_points)
  )
)
comparison

assert_true(nrow(escape_points) > 0, "Preferred escape-point calculation returned no points.")
```

``` r

oldpar <- par(mfrow = c(1, 3))

plot(zones$hazard_zone, col = "grey90", border = "grey40", main = "Wrong\nland-only boundary")
plot(roads_clean, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.35), lwd = 0.35)
if (!inherits(escape_wrong, "try-error")) {
  plot(escape_wrong, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.45)
}

plot(zones$escape_zone, col = "grey90", border = "grey40", main = "Better\nTEZ + water")
plot(roads_for_escape, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.35), lwd = 0.35)
plot(escape_water, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.45)

plot(escape_boundary_zone, col = "grey90", border = "grey40", main = "Preferred\nroad-aware boundary")
plot(roads_for_escape, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.35), lwd = 0.35)
plot(escape_points, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.45)

par(oldpar)
```

From this point forward, the diagnostic uses:

``` text
hazard_zone          = zones$hazard_zone
escape_zone          = zones$escape_zone
roads_for_escape     = inset-cropped roads
escape_boundary_zone = road-aware TEZ + water boundary
escape_points        = preferred escape points
```

``` r

hazard_zone <- zones$hazard_zone
escape_zone <- zones$escape_zone
dem <- zones$dem
roads <- roads_clean
```

## Prepare Core Inputs

[`prepare_evac_inputs()`](https://el-cordero.github.io/evacpath/reference/prepare_evac_inputs.md)
reads, cleans, projects, and converts the land-only `hazard_zone` into a
polygon if needed. It does not create the road-aware escape boundary;
that is handled separately above.

``` r

inputs <- prepare_evac_inputs(
  hazard_zone = hazard_zone,
  roads = roads,
  dem = dem,
  target_crs = params$target_crs,
  hazard_as_polygon = TRUE,
  dissolve_hazard = TRUE,
  road_exclude = NULL
)

hazard_zone <- inputs$hazard_zone
roads <- inputs$roads
dem <- inputs$dem

assert_true(is_spatvector(hazard_zone), "Prepared hazard_zone is not a SpatVector.")
assert_true(is_spatvector(roads), "Prepared roads are not a SpatVector.")
assert_true(is_spatraster(dem), "Prepared DEM is not a SpatRaster.")
```

## Create the Evacuation Grid

The evacuation grid should be created from the land-only `hazard_zone`,
not the water-combined or road-aware escape zone.

``` r

grid_resolution <- terra::res(dem) * params$grid_multiplier

evac_grid <- make_evac_grid(
  hazard_zone = hazard_zone,
  resolution = grid_resolution
)

assert_true(is_spatvector(evac_grid), "make_evac_grid() did not return a SpatVector.")
assert_true(nrow(evac_grid) > 0, "make_evac_grid() returned no grid cells.")

cat("Grid resolution:", paste(grid_resolution, collapse = " x "), "\n")
cat("Grid cells:", nrow(evac_grid), "\n")
```

``` r

plot(hazard_zone, col = "grey95", border = "grey50", main = "Evacuation grid over land-only TEZ")
plot(evac_grid, add = TRUE, border = adjustcolor("black", alpha.f = 0.25), col = NA)
plot(roads, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.45), lwd = 0.35)
```

## Create the Road Mask

[`make_road_mask()`](https://el-cordero.github.io/evacpath/reference/make_road_mask.md)
buffers the roads and preferred escape points, then combines them. The
mask constrains least-cost movement to the road/pathway network while
still allowing access around escape points.

``` r

road_mask_parts <- make_road_mask(
  roads = roads,
  escape_points = escape_points,
  road_buffer_m = params$road_buffer_m,
  escape_buffer_m = params$escape_buffer_m,
  return_components = TRUE
)

road_mask <- road_mask_parts$mask
roads_buffer <- road_mask_parts$roads_buffer
escape_buffer <- road_mask_parts$escape_buffer

assert_true(is_spatvector(road_mask), "Road mask is not a SpatVector.")
assert_true(is_spatvector(roads_buffer), "roads_buffer is not a SpatVector.")
assert_true(is_spatvector(escape_buffer), "escape_buffer is not a SpatVector.")
```

``` r

plot(hazard_zone, col = "grey95", border = "grey60", main = "Road-constrained movement mask")
plot(road_mask, add = TRUE, col = adjustcolor("grey30", alpha.f = 0.35), border = NA)
plot(escape_points, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.45)
```

## Create Road Origin Points

Origins should be road-based points inside the land-only inundation
zone.

``` r

road_points <- make_road_origins(
  evac_grid = evac_grid,
  roads_buffer = roads_buffer,
  hazard_zone = hazard_zone,
  max_origins = params$max_origins,
  seed = params$seed
)

assert_true(is_spatvector(road_points), "make_road_origins() did not return a SpatVector.")
assert_true(nrow(road_points) > 0, "make_road_origins() returned no origins.")

cat("Road origin points retained:", nrow(road_points), "\n")
```

``` r

plot(hazard_zone, col = "grey95", border = "grey60", main = "Road origin points inside land-only TEZ")
plot(roads, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.35), lwd = 0.35)
plot(road_points, add = TRUE, pch = 21, bg = "dodgerblue", col = "black", cex = 0.45)
plot(escape_points, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.45)
```

## Create the Conductance Surface

The conductance surface is built from the DEM but masked to the
road-constrained movement area. This is the expensive part.
`dem_resolution` can be coarsened for testing.

``` r

dem_resolution <- terra::res(dem) * params$dem_multiplier

conductance <- make_conductance_surface(
  dem = dem,
  road_mask = road_mask,
  resolution = dem_resolution
)

cs_raster <- leastcostpath::rasterise(conductance)

assert_true(is_spatraster(cs_raster), "Conductance rasterization failed.")

cat("Conductance raster resolution:", paste(terra::res(cs_raster), collapse = " x "), "\n")
cat("Conductance raster cells:", terra::ncell(cs_raster), "\n")
```

``` r

plot(cs_raster, main = "Road-constrained conductance surface")
plot(hazard_zone, add = TRUE, border = "black", col = NA)
plot(roads, add = TRUE, col = adjustcolor("grey20", alpha.f = 1), lwd = 0.35)
plot(escape_points, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.45)
```

## Calculate Least-Cost Distance

This section is optional because it can be slow for large study areas.
The packaged example area is small, so the default parameters use all
available origins and destinations.

``` r

escape_points_ltd <- escape_points
if (!is.null(params$max_destinations) && params$max_destinations < nrow(escape_points_ltd)) {
  set.seed(params$seed)
  escape_points_ltd <- escape_points_ltd[sort(sample.int(nrow(escape_points_ltd), params$max_destinations)), ]
}

cat("Escape points available:", nrow(escape_points), "\n")
cat("Escape points used in diagnostic LCP:", nrow(escape_points_ltd), "\n")
```

``` r

distance_points <- calc_min_distance_to_safety(
  cs = conductance,
  origins = road_points,
  destinations = escape_points_ltd,
  include_destinations = TRUE,
  progress = TRUE,
  progress_every = 500,
  check_locations = FALSE
)

assert_true(is_spatvector(distance_points), "calc_min_distance_to_safety() did not return a SpatVector.")
assert_true("distance" %in% names(distance_points), "distance_points does not contain a distance field.")

summary(distance_points$distance)
table(distance_points$type)
```

``` r

plot(hazard_zone, col = "grey95", border = "grey60", main = "Minimum least-cost distance points")
plot(roads, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.30), lwd = 0.35)
plot(distance_points, "distance", add = TRUE)
```

## Convert Distance to Time

[`calc_evac_time()`](https://el-cordero.github.io/evacpath/reference/calc_evac_time.md)
converts distance to time using a walking speed. The default paper-style
value is 1.22 m/s, but local planning scenarios should modify it.

``` r

example_distances <- c(0, 100, 500, 1000, 2000)
data.frame(
  distance_m = example_distances,
  time_min = calc_evac_time(
    distance_m = example_distances,
    walking_speed_mps = params$walking_speed_mps,
    units = "minutes"
  )
)
```

## Create Evacuation Polygons

[`make_evac_polygons()`](https://el-cordero.github.io/evacpath/reference/make_evac_polygons.md)
converts the distance points to Voronoi polygons, calculates evacuation
time, and clips the result to the selected output area. For the broad
time grid, the clip area should be the land-only `hazard_zone`.

``` r

evac_polygons <- make_evac_polygons(
  distance_points = distance_points,
  clip_area = hazard_zone,
  walking_speed_mps = params$walking_speed_mps,
  region_name = params$region_name
)

assert_true(is_spatvector(evac_polygons), "make_evac_polygons() did not return a SpatVector.")
assert_true("EvacTimeAvg" %in% names(evac_polygons), "EvacTimeAvg field is missing.")

summary(evac_polygons$EvacTimeAvg)
```

``` r

plot(evac_polygons, "EvacTimeAvg", border = NA, main = "Evacuation-time polygons")
plot(roads, add = TRUE, col = adjustcolor("grey20", alpha.f = 0.30), lwd = 0.35)
plot(escape_points_ltd, add = TRUE, pch = 22, bg = "red", col = "black", cex = 0.45)
```

## Run the High-Level Wrapper

After the individual steps work, the same logic should run through
[`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md).
The key tsunami-specific arguments are:

``` r

hazard_zone = zones$hazard_zone
escape_zone = zones$escape_zone
escape_roads_inset_x_m = 50
escape_roads_inset_y_m = 50
road_aware_escape_zone = TRUE
```

## Final map check

This map uses land/water as background, the land-only evacuation-time
polygons as the main layer, and the preferred escape points as squares.

``` r

evac_map <- result$time_grid
roads_plot <- crop(result$roads, evac_map)
escape_plot <- crop(result$escape_points, evac_map)

dem_bg <- result$dem
if (!same.crs(dem_bg, evac_map)) {
  dem_bg <- project(dem_bg, crs(evac_map))
}

e <- ext(evac_map)
xpad <- (xmax(e) - xmin(e)) * 0.06
ypad <- (ymax(e) - ymin(e)) * 0.06
e2 <- ext(xmin(e) - xpad, xmax(e) + xpad, ymin(e) - ypad, ymax(e) + ypad)

dem_bg <- crop(dem_bg, e2)
land_water <- ifel(dem_bg > params$land_threshold, 2, 1)
names(land_water) <- "land_water"

bg_cols <- c(
  adjustcolor("lightskyblue1", alpha.f = 0.65),
  adjustcolor("grey92", alpha.f = 1.00)
)
time_cols <- hcl.colors(100, "YlOrRd", rev = TRUE)

oldpar <- par(mar = c(4, 4, 3, 5), mgp = c(2.2, 0.7, 0), las = 1, bg = "white", xpd = FALSE)

plot(
  land_water,
  ext = e2,
  col = bg_cols,
  legend = FALSE,
  axes = TRUE,
  box = FALSE,
  main = "Modeled Pedestrian Evacuation Time",
  cex.main = 1.1
)

plot(
  evac_map,
  "EvacTimeAvg",
  add = TRUE,
  col = time_cols,
  border = NA,
  plg = list(title = "Minutes", cex = 0.75, title.cex = 0.85, x = "right")
)

plot(roads_plot, add = TRUE, col = adjustcolor("grey25", alpha.f = 0.30), lwd = 0.30)
plot(escape_plot, add = TRUE, pch = 22, bg = adjustcolor("red", alpha.f = 0.75), col = "black", cex = 0.38, lwd = 0.35)

legend(
  "topright",
  legend = c("Escape / safety points", "Roads", "Land", "Water"),
  pch = c(22, NA, 15, 15),
  pt.bg = c("red", NA, "grey92", "lightskyblue1"),
  col = c("black", adjustcolor("grey25", alpha.f = 0.5), "grey92", "lightskyblue1"),
  lty = c(NA, 1, NA, NA),
  lwd = c(NA, 1, NA, NA),
  pt.cex = c(0.8, NA, 1.1, 1.1),
  bty = "n",
  cex = 0.7,
  inset = 0.02
)
par(oldpar)
```

## Write Outputs

[`write_evac_outputs()`](https://el-cordero.github.io/evacpath/reference/write_evac_outputs.md)
writes the major spatial outputs from a completed result object. This
should only run after the diagnostic workflow succeeds.

``` r

write_evac_outputs(
  result,
  output_dir = params$output_dir,
  prefix = "example"
)

list.files(params$output_dir, full.names = TRUE)
```

## Troubleshooting checklist

If escape points look wrong, check these first:

1.  Did you create both `hazard_zone` and `escape_zone` with
    [`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)?
2.  Did you crop the roads used for escape detection with
    [`crop_roads_to_inner_extent()`](https://el-cordero.github.io/evacpath/reference/crop_roads_to_inner_extent.md)?
3.  Did you combine buffered roads with the escape zone using
    [`make_road_aware_escape_zone()`](https://el-cordero.github.io/evacpath/reference/make_road_aware_escape_zone.md)?
4.  Did you use the road-aware boundary for
    [`find_escape_points()`](https://el-cordero.github.io/evacpath/reference/find_escape_points.md)?
5.  Does the DEM-derived land/water mask look correct?
6.  If land/water are reversed, did you set `dem_sign_multiplier = -1`?
7.  Are piers, ferry routes, or non-road features still present in the
    road layer?
8.  Is the target CRS projected in meters?
9.  Are you using `dem_resolution` to coarsen the conductance raster for
    testing, not only `grid_resolution`?

The expected tsunami pattern is:

``` r

zones <- prepare_tsunami_zones(inundation, dem, target_crs = target_crs)

roads_for_escape <- crop_roads_to_inner_extent(
  roads = roads,
  zone = zones$escape_zone,
  inset_x_m = 50,
  inset_y_m = 50
)

escape_boundary_zone <- make_road_aware_escape_zone(
  escape_zone = zones$escape_zone,
  roads = roads_for_escape,
  road_buffer_m = 2,
  crop_buffer_m = 3
)

escape_points <- find_escape_points(
  hazard_zone = escape_boundary_zone,
  roads = roads_for_escape
)

result <- run_evacpath(
  hazard_zone = zones$hazard_zone,
  escape_zone = zones$escape_zone,
  roads = roads,
  dem = zones$dem,
  target_crs = target_crs,
  escape_roads_inset_x_m = 50,
  escape_roads_inset_y_m = 50,
  road_aware_escape_zone = TRUE
)
```

## References

Cordero, E., Ruiz Vélez, R., Huérfano Moreno, V., Sherman, C., 2025.
Enhancing tsunami evacuation strategies in Puerto Rico using open-source
least-cost path analysis. J. Disaster Sci. Manag. 1, 18.
<https://doi.org/10.1007/s44367-025-00018-y>

Lewis, J., 2023. leastcostpath: Modelling Pathways and Movement
Potential Within a Landscape.

Lewis, J., 2021. Probabilistic Modelling for Incorporating Uncertainty
in Least Cost Path Results: a Postdictive Roman Road Case Study. Journal
of Archaeological Method and Theory 28, 911-924.
<https://doi.org/10.1007/s10816-021-09522-w>
