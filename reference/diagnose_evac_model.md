# Diagnose evacuation-model inputs

Runs spatial quality assurance and quality control checks before or
after evacuation modeling. Unlike the modeling workflow, diagnostics
collect issues into a report so several input problems can be reviewed
together.

## Usage

``` r
diagnose_evac_model(
  hazard_zone,
  roads,
  dem,
  target_crs = NULL,
  escape_zone = NULL,
  origins = NULL,
  destinations = NULL,
  conductance = NULL,
  check_reachability = TRUE,
  sample_size = 100,
  ...
)
```

## Arguments

- hazard_zone:

  Hazard-zone polygon, raster, or file path.

- roads:

  Road/pathway line layer or file path.

- dem:

  Digital elevation model raster or file path.

- target_crs:

  Optional target coordinate reference system.

- escape_zone:

  Optional escape-boundary zone.

- origins:

  Optional modeled origin points.

- destinations:

  Optional escape/safety destination points.

- conductance:

  Optional `leastcostpath` conductance surface. When supplied with
  origins and destinations, routing checks are run.

- check_reachability:

  Logical. Attempt sampled routing checks when routing inputs are
  available.

- sample_size:

  Maximum number of origins used for sampled reachability checks.

- ...:

  Reserved for future extensions.

## Value

An `evac_diagnostics` list with `issues`, `summary`,
`diagnostic_layers`, and `metadata`.

## Examples

``` r
dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
  vals = 1, crs = "EPSG:3857")
hazard <- terra::as.polygons(dem, dissolve = TRUE)
roads <- terra::vect(matrix(c(0, 2.5, 5, 2.5), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
diagnostics <- diagnose_evac_model(hazard, roads, dem)
diagnostics
#> <evac_diagnostics>
#> Errors: 0 | Warnings: 0 | Info: 1
#>  severity   check
#>      info routing
#>                                                                                                 message
#>  Reachability checks were skipped because conductance, origins, and destinations were not all supplied.
#>  n_affected
#>          NA
has_errors(diagnostics)
#> [1] FALSE
```
