# Get started with evacpath

`evacpath` estimates road-constrained pedestrian distance to safety and
converts that modeled distance into an evacuation-time surface. A
practical workflow needs a hazard zone, a road or pathway network, an
elevation raster, and a projected coordinate reference system (CRS) in
meters.

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

The compact run used for the figures and summaries below is clipped to a
small projected window. It uses 40 sampled road origins and 12 candidate
safety exits.

| Input                        | Example value |
|:-----------------------------|:--------------|
| Coordinate reference system  | EPSG:32748    |
| Hazard-zone area (square km) | 4.048         |
| Road features                | 254           |
| Candidate safety exits       | 12            |
| Sampled road origins         | 40            |

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
```

![Modeled evacuation time to safety for the compact packaged
example.](../reference/figures/pkgdown-example-time.png)

Modeled evacuation time to safety for the compact packaged example.

The example summary is a description of the modeled road-origin results,
not a measure of observed evacuation behavior.

| Modeled output                 | Example value |
|:-------------------------------|--------------:|
| Minimum modeled time (minutes) |          0.31 |
| Median modeled time (minutes)  |         10.09 |
| Mean modeled time (minutes)    |          9.65 |
| Maximum modeled time (minutes) |         22.84 |
| Origins                        |         40.00 |
| Destinations                   |         12.00 |
| Walking speed (m/s)            |          1.22 |

## What you get back

[`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
returns a named list. The main layers are summarized below so you can
inspect or write only the outputs needed for the analysis.

| Object | Purpose |
|:---|:---|
| hazard_zone | Land-only area used for evacuation origins and mapped output. |
| escape_points | Candidate safety exits identified at the selected escape boundary. |
| road_points | Sampled road-based origins used for least-cost calculations. |
| distance_points | Modeled distance to safety for sampled origins and zero-distance exits. |
| evac_polygons / time_grid | Polygonized modeled distance and time surface for map output. |

Use `result$evac_polygons`, `result$distance_points`,
`result$time_grid`, and `result$escape_points` for the mapped and point
outputs. Run
[`diagnose_evac_model()`](https://el-cordero.github.io/evacpath/reference/diagnose_evac_model.md)
before interpreting a result to make coordinate-system, geometry,
extent, and reachability checks explicit.
