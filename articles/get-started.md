# Get started with evacpath

`evacpath` estimates road-constrained pedestrian distance to safety and
converts that distance into an evacuation-time surface. A practical
workflow needs a hazard zone, a road or pathway network, an elevation
raster, and a projected coordinate reference system (CRS) in meters.

## Install and load

``` r

install.packages("evacpath")
library(evacpath)
library(terra)
```

## Load the packaged example data

The package includes small example inputs for learning the workflow.
They are not a substitute for local hazard, road, terrain, or
evacuation-planning data.

``` r

dem <- rast(system.file("extdata/dem.tif", package = "evacpath"))
roads <- vect(system.file("extdata/rds.gpkg", package = "evacpath"))
inundation <- rast(system.file(
  "extdata/tsunami_inundation_depth.tif",
  package = "evacpath"
))

zones <- prepare_tsunami_zones(
  inundation = inundation,
  dem = dem,
  target_crs = "EPSG:32748"
)
```

## Run the workflow

For a first pass, use a modest number of origins and destinations.
Remove or raise those limits only after reviewing the input layers and
assumptions.

``` r

result <- run_evacpath(
  hazard_zone = zones$hazard_zone,
  escape_zone = zones$escape_zone,
  roads = roads,
  dem = zones$dem,
  target_crs = "EPSG:32748",
  max_origins = 100,
  max_destinations = 25,
  walking_speed_mps = 1.22
)

result$evac_polygons
result$distance_points
```

Before interpreting a map, review the coordinate system, terrain,
hazard-zone definition, road connectivity, escape-point logic, and
walking-speed assumption. Use \[diagnose_evac_model()\] to make those
checks explicit.
