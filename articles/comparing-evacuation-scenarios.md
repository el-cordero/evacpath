# Comparing evacuation scenarios with evacpath

`evacpath` can compare pedestrian-evacuation assumptions without
changing the underlying study inputs. This article uses the packaged
example data and clips all spatial inputs to a small focus area before
modeling.

## Load example inputs

``` r

library(evacpath)
library(terra)

focus <- ext(669000, 675000, 9223000, 9225000)

dem <- crop(rast(system.file("extdata/dem.tif", package = "evacpath")), focus)
inundation <- crop(
  rast(system.file("extdata/tsunami_inundation_depth.tif", package = "evacpath")),
  focus
)
roads <- crop(vect(system.file("extdata/rds.gpkg", package = "evacpath")), focus)

zones <- prepare_tsunami_zones(
  inundation = inundation,
  dem = dem,
  target_crs = "EPSG:32748"
)

roads <- clean_roads(
  roads,
  exclude = list(field = "man_made", values = "pier"),
  target_crs = "EPSG:32748"
)
```

## Run a baseline model

`walking_speed_mps` controls conversion from route distance to
evacuation time. The `lcp_*` arguments control the conductance surface
and can change modeled route geometry.

``` r

baseline <- run_evacpath(
  hazard_zone = zones$hazard_zone,
  escape_zone = zones$escape_zone,
  roads = roads,
  dem = zones$dem,
  target_crs = "EPSG:32748",
  max_origins = 500,
  max_destinations = 100,
  walking_speed_mps = 1.22,
  keep_routes = TRUE
)
```

## Compare walking speed and path assumptions

``` r

comparison <- compare_evac_scenarios(
  hazard_zone = zones$hazard_zone,
  escape_zone = zones$escape_zone,
  roads = roads,
  dem = zones$dem,
  target_crs = "EPSG:32748",
  max_origins = 500,
  max_destinations = 100,
  scenarios = list(
    baseline = list(walking_speed_mps = 1.22),
    slow_walkers = list(walking_speed_mps = 0.75),
    alternative_neighbours = list(lcp_neighbours = 8)
  )
)

comparison$summary
```

![Scenario sensitivity in modeled evacuation
time.](../reference/figures/pkgdown-example-scenarios.png)

Scenario sensitivity in modeled evacuation time.

| Scenario             | Walking speed | Median min. | Mean min. | Maximum min. |
|:---------------------|--------------:|------------:|----------:|-------------:|
| baseline             |          1.22 |        7.27 |      9.75 |        22.84 |
| slow_walkers         |          0.75 |       11.83 |     15.86 |        37.15 |
| conservative_routing |          1.22 |        7.48 |     10.26 |        23.96 |

## Diagnose inputs

Diagnostics collect coordinate reference system, geometry, overlap,
elevation, origin, destination, and optional reachability issues in one
report.

``` r

diagnostics <- diagnose_evac_model(
  hazard_zone = baseline$hazard_zone,
  roads = baseline$roads,
  dem = baseline$dem,
  escape_zone = baseline$escape_zone,
  origins = baseline$road_points,
  destinations = baseline$escape_points,
  conductance = baseline$conductance
)

diagnostics
has_errors(diagnostics)
```

The generator also records a compact QA/QC result from the same packaged
run. It is a snapshot of the supplied inputs and settings, not a general
guarantee about a new study area.

| QA/QC check            | Result      |
|:-----------------------|:------------|
| Errors                 | 0           |
| Warnings               | 1           |
| Informational checks   | 2           |
| Road features          | 193         |
| Sampled origins        | 40          |
| Candidate safety exits | 12          |
| DEM resolution (m)     | 5.12 x 5.12 |

## Map bottlenecks

Routes are retained only when `keep_routes = TRUE`. This keeps ordinary
runs lightweight while allowing route-density analysis when it is
needed.

``` r

bottlenecks <- map_evac_bottlenecks(evac_result = baseline)

plot(bottlenecks$density_raster)
plot(bottlenecks$high_density_polygons, add = TRUE)
```

![Modeled high-use corridors from the compact packaged
example.](../reference/figures/pkgdown-example-corridors.png)

Modeled high-use corridors from the compact packaged example.
