# evacpath 0.1.1

* Added package website and bug-report URLs.
* Updated the maintainer email address.
* Removed internal paper drafts and legacy reference scripts from the public repository.
* Cleaned the diagnostic vignette and its local PDF rendering workflow.

* Added `crop_roads_to_inner_extent()` with separate x/y inset controls for escape-point quality assurance and quality control.
* Added `make_road_aware_escape_zone()` to combine buffered road corridors with the tsunami escape zone before escape points are generated.
* Added `roads_for_escape`, `escape_roads_inset_x_m`, `escape_roads_inset_y_m`, `road_aware_escape_zone`, `escape_zone_road_buffer_m`, and `escape_zone_crop_buffer_m` arguments to `run_evacpath()`.
* Added a package-level help page so `?evacpath` works after documentation/install.
* Reworked the README and diagnostic example so package documentation is place-agnostic.
* Added README figures from the packaged example workflow.
* Removed old compatibility alias documentation and wrappers from the public API.

# evacpath 0.1.0.9005

* Added tsunami-specific `prepare_tsunami_zones()` helper for separate land-only hazard zones and TEZ-plus-water escape zones.
* Added `make_roads_in_zone()` for reproducing the original buffered-road/inundation area logic.

# evacpath 0.1.0.9000

* Initial package skeleton from evacuation analysis scripts.
