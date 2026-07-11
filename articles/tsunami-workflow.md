# Tsunami evacuation workflow

Tsunami workflows often need different zones for mapped exposure and for
finding a meaningful inland exit.
[`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)
makes those roles explicit.

## Three spatial roles

- The **land-only hazard zone** is used to generate road origins and
  clip final time outputs.
- The **water-combined escape zone** combines inundated land with water
  so the shoreline is not treated as an artificial safety boundary.
- The **road-aware escape boundary** adds buffered road corridors before
  escape points are found, preserving bridge, causeway, and walkway
  connections that may otherwise disappear from a land-water split.

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

Inspect the local hazard boundary, road network, elevation sign
convention, and projected CRS before relying on candidate escape points
or modeled times.
