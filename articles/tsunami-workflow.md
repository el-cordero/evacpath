# Tsunami evacuation workflow

Tsunami workflows often need different zones for mapped exposure and for
finding a meaningful inland exit.
[`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)
makes those roles explicit.

## Three spatial roles

| Object | Role | Used for | Common mistake avoided |
|:---|:---|:---|:---|
| Land-only hazard zone | Origin and mapped-output area | Road origins and final time outputs | Mapping through water or starting origins offshore |
| Water-combined escape zone | Meaningful inland exit context | Avoiding coastline exits | Treating the shoreline as an automatic safety boundary |
| Road-aware escape boundary | Road-preserving exit-detection boundary | Finding candidate safety exits | Dropping bridge, causeway, or walkway connections |

![The compact example shows land-only hazard mapping, roads, and
candidate safety
exits.](../reference/figures/pkgdown-example-inputs.png)

The compact example shows land-only hazard mapping, roads, and candidate
safety exits.

The water-combined escape zone is a processing layer, so it is not shown
as a separate planning boundary in this compact map. Its role is to
prevent a land-water split from creating artificial coastline exits.

## Prepare the zones

``` r

zones <- prepare_tsunami_zones(
  inundation = inundation,
  dem = dem,
  target_crs = "EPSG:32748",
  inundation_threshold = 0,
  dem_sign_multiplier = 1
)

roads_for_escape <- crop_roads_to_inner_extent(
  roads = roads,
  zone = zones$escape_zone,
  inset_x_m = 250,
  inset_y_m = 250
)

escape_boundary_zone <- make_road_aware_escape_zone(
  escape_zone = zones$escape_zone,
  roads = roads_for_escape,
  road_buffer_m = 2,
  crop_buffer_m = 3
)
```

## Model travel to safety

``` r

result <- run_evacpath(
  hazard_zone = zones$hazard_zone,
  escape_zone = zones$escape_zone,
  roads = roads,
  roads_for_escape = roads_for_escape,
  dem = zones$dem,
  target_crs = "EPSG:32748",
  road_aware_escape_zone = TRUE,
  escape_zone_road_buffer_m = 2,
  escape_zone_crop_buffer_m = 3
)
```

![Modeled evacuation time to safety for the compact tsunami
example.](../reference/figures/pkgdown-example-time.png)

Modeled evacuation time to safety for the compact tsunami example.

| Modeled output                 | Example value |
|:-------------------------------|--------------:|
| Minimum modeled time (minutes) |          0.31 |
| Median modeled time (minutes)  |         10.09 |
| Mean modeled time (minutes)    |          9.65 |
| Maximum modeled time (minutes) |         22.84 |
| Origins                        |         40.00 |
| Destinations                   |         12.00 |
| Walking speed (m/s)            |          1.22 |

Inspect the local hazard boundary, road network, elevation sign
convention, and projected CRS before relying on candidate escape points
or modeled times.
