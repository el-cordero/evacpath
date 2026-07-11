# Example workflow

This gallery uses the packaged example data in a focused projected
window. It illustrates the package workflow and the layers to inspect;
it is not a finished evacuation plan or a substitute for local review.

## Example inputs

![Example inputs and candidate safety
exits.](../reference/figures/pkgdown-example-inputs.png)

Example inputs and candidate safety exits.

| Input                        | Example value |
|:-----------------------------|:--------------|
| Coordinate reference system  | EPSG:32748    |
| Hazard-zone area (square km) | 4.048         |
| Road features                | 254           |
| Candidate safety exits       | 12            |
| Sampled road origins         | 40            |

## Candidate safety exits

The **hazard zone** is the land-only area used for evacuation origins
and mapped outputs. The **escape zone** combines the inundated area with
water so the shoreline is not treated as an artificial exit. Candidate
safety exits are road intersections with the selected escape boundary,
not confirmed safe locations.

## Modeled evacuation time

![Modeled evacuation time to
safety.](../reference/figures/pkgdown-example-time.png)

Modeled evacuation time to safety.

The time surface converts modeled least-cost distance to safety with the
chosen walking speed. It is sensitive to the elevation surface, road
mask, escape-point logic, cost function, and routing neighbourhood.

| Modeled output                 | Example value |
|:-------------------------------|--------------:|
| Minimum modeled time (minutes) |          0.31 |
| Median modeled time (minutes)  |         10.09 |
| Mean modeled time (minutes)    |          9.65 |
| Maximum modeled time (minutes) |         22.84 |
| Origins                        |         40.00 |
| Destinations                   |         12.00 |
| Walking speed (m/s)            |          1.22 |

## Scenario comparison

![Scenario sensitivity in modeled evacuation
time.](../reference/figures/pkgdown-example-scenarios.png)

Scenario sensitivity in modeled evacuation time.

The slower-walker scenario changes the time conversion. The
conservative-routing scenario changes least-cost path settings and may
therefore change both modeled route geometry and distance.

| Scenario | Walking speed | Median min. | Mean min. | Maximum min. | Assumption |
|:---|---:|---:|---:|---:|:---|
| baseline | 1.22 | 7.27 | 9.75 | 22.84 | Baseline walking-speed and routing assumptions. |
| slow_walkers | 0.75 | 11.83 | 15.86 | 37.15 | Changes time conversion; route distance is held by the same routing setup. |
| conservative_routing | 1.22 | 7.48 | 10.26 | 23.96 | Uses 8 neighbours and a 30 percent maximum slope. |

## Outputs users can write

[`write_evac_outputs()`](https://el-cordero.github.io/evacpath/reference/write_evac_outputs.md)
writes selected spatial outputs to an explicit directory. For
`prefix = "study_area"`, typical filenames include
`study_area_escape_points.gpkg`, `study_area_distance_points.gpkg`,
`study_area_evac_polygons.gpkg`, and `study_area_time_grid.gpkg`. The
returned object keeps the following layers available for inspection
before anything is written.

| Object | Purpose |
|:---|:---|
| hazard_zone | Land-only area used for evacuation origins and mapped output. |
| escape_points | Candidate safety exits identified at the selected escape boundary. |
| road_points | Sampled road-based origins used for least-cost calculations. |
| distance_points | Modeled distance to safety for sampled origins and zero-distance exits. |
| evac_polygons / time_grid | Polygonized modeled distance and time surface for map output. |

The reproducible generator for this gallery is
`inst/scripts/make-pkgdown-example-outputs.R`. It uses the packaged data
and creates the small figures and CSV summaries included here.
