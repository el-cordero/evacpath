# Using evacpath in a new region

For a new region, `evacpath` expects three core spatial inputs:

1.  a hazard or inundation zone,
2.  a road/pathway network, and
3.  a DEM or elevation raster.

The most important requirement is that distance calculations should use
a projected coordinate reference system in meters.

The workflow builds on open-source least-cost path methods for
evacuation planning (Cordero et al. 2025) and uses `leastcostpath` for
least-cost path and movement-potential modeling (Lewis 2023; Lewis
2021).

## Regional checklist

| Item | Review before modeling |
|:---|:---|
| Hazard or inundation input | A defined hazard footprint and its intended threshold. |
| Road or pathway input | A connected, suitable pedestrian network with documented attributes. |
| DEM or elevation input | Coverage across the study area, elevation sign convention, and resolution. |
| Target CRS | A projected CRS in meters for distance calculations. |
| Walking speed | A documented assumption appropriate to the planning scenario. |
| Local exclusions | Piers, private roads, closures, or other locally unsuitable features. |
| Output directory | An explicit directory when using write_evac_outputs(). |
| QA/QC review | CRS, geometry, extent, origins, exits, and reachability checks. |

``` r

library(evacpath)
```

## Minimal workflow

``` r

result <- run_evacpath(
  hazard_zone = "path/to/hazard_zone.gpkg",
  roads = "path/to/roads.gpkg",
  dem = "path/to/dem.tif",
  target_crs = "EPSG:XXXX",
  region_name = "New region",
  walking_speed_mps = 1.22
)
```

For context, this is the model result returned by a compact run using
the packaged inputs. A new region should be interpreted only after its
own input and QA/QC review.

![Modeled evacuation time to safety for the compact packaged
example.](../reference/figures/pkgdown-example-time.png)

Modeled evacuation time to safety for the compact packaged example.

| Modeled output                 | Example value |
|:-------------------------------|--------------:|
| Minimum modeled time (minutes) |          0.31 |
| Median modeled time (minutes)  |         10.09 |
| Mean modeled time (minutes)    |          9.65 |
| Maximum modeled time (minutes) |         22.84 |
| Origins                        |         40.00 |
| Destinations                   |         12.00 |
| Walking speed (m/s)            |          1.22 |

## Common customizations

``` r

result <- run_evacpath(
  hazard_zone = "path/to/hazard_zone.gpkg",
  roads = "path/to/roads.gpkg",
  dem = "path/to/dem.tif",
  target_crs = "EPSG:XXXX",
  region_name = "New region",

  # Road and escape-point geometry assumptions
  road_buffer_m = 2,
  escape_buffer_m = 5,
  final_road_buffer_m = 3,

  # Origin-point density
  grid_resolution = 50,
  max_origins = NULL,

  # Travel-time assumption
  walking_speed_mps = 1.22,

  # Output clipping
  clip_mode = "road_hazard"
)
```

## Case-specific preprocessing

Keep region-specific choices outside the package. For example, if your
DEM uses negative elevation for land, correct it before calling
[`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md).
If your road layer contains piers or other unsuitable features, remove
them with
[`clean_roads()`](https://el-cordero.github.io/evacpath/reference/clean_roads.md).

``` r

roads <- clean_roads(
  roads = "path/to/roads.gpkg",
  exclude = list(field = "road_type", values = c("pier", "private")),
  target_crs = "EPSG:XXXX"
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
