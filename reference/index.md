# Package index

## Package overview

Package-level help and a concise workflow overview.

- [`evacpath`](https://el-cordero.github.io/evacpath/reference/evacpath-package.md)
  [`evacpath-package`](https://el-cordero.github.io/evacpath/reference/evacpath-package.md)
  : evacpath: Least-cost pedestrian evacuation modeling in R

## Complete workflow

Run the full evacuation modeling workflow and write outputs.

- [`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
  : Run the full evacuation-path modeling workflow
- [`make_output_clip_area()`](https://el-cordero.github.io/evacpath/reference/make_output_clip_area.md)
  : Make an output clip area for evacuation polygons
- [`write_evac_outputs()`](https://el-cordero.github.io/evacpath/reference/write_evac_outputs.md)
  : Write evacpath outputs to disk

## Input preparation

Read, clean, project, and prepare hazard, road, elevation, and tsunami
inputs.

- [`read_spatial()`](https://el-cordero.github.io/evacpath/reference/read_spatial.md)
  : Read a spatial input
- [`prepare_evac_inputs()`](https://el-cordero.github.io/evacpath/reference/prepare_evac_inputs.md)
  : Read and project the core evacuation inputs
- [`prepare_hazard_zone()`](https://el-cordero.github.io/evacpath/reference/prepare_hazard_zone.md)
  : Prepare a hazard zone from an inundation raster
- [`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)
  : Prepare separate tsunami zones for escape analysis and visualization
- [`clean_roads()`](https://el-cordero.github.io/evacpath/reference/clean_roads.md)
  : Clean a road/pathway network
- [`crop_roads_to_inner_extent()`](https://el-cordero.github.io/evacpath/reference/crop_roads_to_inner_extent.md)
  : Crop roads to an inset extent before escape-point detection
- [`make_region_area()`](https://el-cordero.github.io/evacpath/reference/make_region_area.md)
  : Create a broader analysis region around a study area
- [`make_roads_in_zone()`](https://el-cordero.github.io/evacpath/reference/make_roads_in_zone.md)
  : Create a buffered road area inside an inundation or analysis zone
- [`make_road_aware_escape_zone()`](https://el-cordero.github.io/evacpath/reference/make_road_aware_escape_zone.md)
  : Add buffered road corridors to an escape-boundary zone

## Evacuation geometry

Build origin grids, road masks, escape points, and evacuation polygons.

- [`make_evac_grid()`](https://el-cordero.github.io/evacpath/reference/make_evac_grid.md)
  : Create an evacuation grid
- [`make_road_origins()`](https://el-cordero.github.io/evacpath/reference/make_road_origins.md)
  : Create road-based origin points inside the evacuation zone
- [`find_escape_points()`](https://el-cordero.github.io/evacpath/reference/find_escape_points.md)
  : Identify escape/safety points where roads cross the hazard-zone
  boundary
- [`make_road_mask()`](https://el-cordero.github.io/evacpath/reference/make_road_mask.md)
  : Create a road-constrained analysis mask
- [`make_evac_polygons()`](https://el-cordero.github.io/evacpath/reference/make_evac_polygons.md)
  : Create evacuation-distance and evacuation-time polygons

## Least-cost modeling

Build conductance surfaces and calculate least-cost distance and
evacuation time.

- [`make_conductance_surface()`](https://el-cordero.github.io/evacpath/reference/make_conductance_surface.md)
  : Create a slope-based conductance surface
- [`calc_min_distance_to_safety()`](https://el-cordero.github.io/evacpath/reference/calc_min_distance_to_safety.md)
  : Calculate minimum least-cost distance from origins to safety
- [`calc_evac_time()`](https://el-cordero.github.io/evacpath/reference/calc_evac_time.md)
  : Convert distance to evacuation time
- [`calculate_lc_path()`](https://el-cordero.github.io/evacpath/reference/calculate_lc_path.md)
  : Calculate a least-cost path between one origin and one destination
- [`calculate_min_dist()`](https://el-cordero.github.io/evacpath/reference/calculate_min_dist.md)
  : Calculate the minimum path distance from a list of least-cost paths
- [`interpolate_distance_surface()`](https://el-cordero.github.io/evacpath/reference/interpolate_distance_surface.md)
  : Interpolate a distance surface from least-cost distance points

## Diagnostics, scenarios, and validation

Compare assumptions, map bottlenecks, diagnose models, and validate
routes.

- [`diagnose_evac_model()`](https://el-cordero.github.io/evacpath/reference/diagnose_evac_model.md)
  : Diagnose evacuation-model inputs
- [`has_errors()`](https://el-cordero.github.io/evacpath/reference/has_errors.md)
  : Test whether diagnostics contain errors
- [`compare_evac_scenarios()`](https://el-cordero.github.io/evacpath/reference/compare_evac_scenarios.md)
  : Compare evacuation scenarios
- [`map_evac_bottlenecks()`](https://el-cordero.github.io/evacpath/reference/map_evac_bottlenecks.md)
  : Map modeled evacuation bottlenecks
- [`validate_evac_routes()`](https://el-cordero.github.io/evacpath/reference/validate_evac_routes.md)
  : Validate modeled evacuation routes
