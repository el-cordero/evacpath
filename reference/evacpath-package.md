# evacpath: Least-cost pedestrian evacuation modeling in R

`evacpath` provides tools for modeling pedestrian evacuation distance
and travel time from hazard zones to safety areas using road-constrained
least-cost path analysis.

## Details

The package is organized as a set of modular functions. Typical
workflows use
[`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)
to create tsunami-specific hazard and escape zones,
[`crop_roads_to_inner_extent()`](https://el-cordero.github.io/evacpath/reference/crop_roads_to_inner_extent.md)
and
[`make_road_aware_escape_zone()`](https://el-cordero.github.io/evacpath/reference/make_road_aware_escape_zone.md)
to prevent false escape points along artificial study-area boundaries
while retaining bridge and walkway corridors,
[`find_escape_points()`](https://el-cordero.github.io/evacpath/reference/find_escape_points.md)
to identify candidate exits,
[`make_conductance_surface()`](https://el-cordero.github.io/evacpath/reference/make_conductance_surface.md)
to build a slope-based conductance surface, and
[`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
to run the full workflow.

## See also

Useful links:

- <https://el-cordero.github.io/evacpath/>

- <https://github.com/el-cordero/evacpath>

- Report bugs at <https://github.com/el-cordero/evacpath/issues>

## Author

**Maintainer**: Elvin Cordero <elvin.cordero@seamountgeo.com>
