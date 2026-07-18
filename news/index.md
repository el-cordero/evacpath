# Changelog

## evacpath 0.2.0

- Added CRAN installation instructions, the canonical CRAN package page,
  the CRAN package DOI, and a stable public logo URL to the README.
- Added `lcp_cost_function`, `lcp_neighbours`, `lcp_crit_slope`,
  `lcp_max_slope`, and `lcp_args` controls so
  [`make_conductance_surface()`](https://el-cordero.github.io/evacpath/reference/make_conductance_surface.md)
  and
  [`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md)
  expose `leastcostpath` slope-surface assumptions.
- Added opt-in route retention with
  `calc_min_distance_to_safety(return_routes = TRUE)` and
  `run_evacpath(keep_routes = TRUE)`.
- Added
  [`compare_evac_scenarios()`](https://el-cordero.github.io/evacpath/reference/compare_evac_scenarios.md)
  for comparison-ready scenario summaries and combined spatial outputs.
- Added
  [`map_evac_bottlenecks()`](https://el-cordero.github.io/evacpath/reference/map_evac_bottlenecks.md)
  for modeled route-density and high-use corridor mapping.
- Added
  [`diagnose_evac_model()`](https://el-cordero.github.io/evacpath/reference/diagnose_evac_model.md)
  and
  [`has_errors()`](https://el-cordero.github.io/evacpath/reference/has_errors.md)
  for spatial quality assurance and quality control checks.
- Added
  [`validate_evac_routes()`](https://el-cordero.github.io/evacpath/reference/validate_evac_routes.md)
  for buffer-overlap, Hausdorff-distance, and optional
  path-deviation-index comparisons against reference routes.
- Refreshed the pkgdown site with a dark-red navigation theme, visible
  result panels in every guide, and compact static example outputs
  generated from packaged data.
- Added package citation metadata, community policies, cross-platform
  continuous integration, and a repeatable source-archive URI audit.
- Made vignette result figures package-internal so installed guides do
  not depend on build-machine paths.

## evacpath 0.1.1

- Added package website and bug-report URLs.

- Updated the maintainer email address.

- Removed internal paper drafts and legacy reference scripts from the
  public repository.

- Cleaned the diagnostic vignette and its local PDF rendering workflow.

- Added
  [`crop_roads_to_inner_extent()`](https://el-cordero.github.io/evacpath/reference/crop_roads_to_inner_extent.md)
  with separate x/y inset controls for escape-point quality assurance
  and quality control.

- Added
  [`make_road_aware_escape_zone()`](https://el-cordero.github.io/evacpath/reference/make_road_aware_escape_zone.md)
  to combine buffered road corridors with the tsunami escape zone before
  escape points are generated.

- Added `roads_for_escape`, `escape_roads_inset_x_m`,
  `escape_roads_inset_y_m`, `road_aware_escape_zone`,
  `escape_zone_road_buffer_m`, and `escape_zone_crop_buffer_m` arguments
  to
  [`run_evacpath()`](https://el-cordero.github.io/evacpath/reference/run_evacpath.md).

- Added a package-level help page so
  [`?evacpath`](https://el-cordero.github.io/evacpath/reference/evacpath-package.md)
  works after documentation/install.

- Reworked the README and diagnostic example so package documentation is
  place-agnostic.

- Added README figures from the packaged example workflow.

- Removed old compatibility alias documentation and wrappers from the
  public API.

## evacpath 0.1.0.9005

- Added tsunami-specific
  [`prepare_tsunami_zones()`](https://el-cordero.github.io/evacpath/reference/prepare_tsunami_zones.md)
  helper for separate land-only hazard zones and TEZ-plus-water escape
  zones.
- Added
  [`make_roads_in_zone()`](https://el-cordero.github.io/evacpath/reference/make_roads_in_zone.md)
  for reproducing the original buffered-road/inundation area logic.

## evacpath 0.1.0.9000

- Initial package skeleton from evacuation analysis scripts.
