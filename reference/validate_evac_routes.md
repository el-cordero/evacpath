# Validate modeled evacuation routes

Compares modeled routes with official, observed, collaborator-provided,
or manually digitized reference routes. Buffer overlap and
Hausdorff-distance comparisons are calculated with `sf`. Path deviation
index comparisons use
[`leastcostpath::PDI_validation()`](https://rdrr.io/pkg/leastcostpath/man/PDI_validation.html)
when available and compatible with the supplied routes.

## Usage

``` r
validate_evac_routes(
  modeled_routes,
  reference_routes,
  method = c("pdi", "buffer_overlap", "hausdorff", "all"),
  buffer_m = 25,
  by = NULL,
  ...
)
```

## Arguments

- modeled_routes:

  An `sf` LINESTRING or MULTILINESTRING object.

- reference_routes:

  An `sf` LINESTRING or MULTILINESTRING object.

- method:

  Comparison method: `"pdi"`, `"buffer_overlap"`, `"hausdorff"`, or
  `"all"`.

- buffer_m:

  Buffer distance in projected coordinate reference system units,
  typically meters.

- by:

  Optional column name used to match modeled and reference routes. When
  `NULL`, each modeled route is matched to its nearest reference route.

- ...:

  Reserved for future extensions.

## Value

An `evac_route_validation` list with route-level `metrics`,
`matched_routes`, requested `method`, `buffer_m`, and `summary`.

## Examples

``` r
modeled <- sf::st_sf(
  id = "route_a",
  geometry = sf::st_sfc(
    sf::st_linestring(matrix(c(0, 0, 100, 0), ncol = 2, byrow = TRUE)),
    crs = 3857
  )
)
reference <- sf::st_sf(
  id = "route_a",
  geometry = sf::st_sfc(
    sf::st_linestring(matrix(c(0, 5, 100, 5), ncol = 2, byrow = TRUE)),
    crs = 3857
  )
)
validate_evac_routes(modeled, reference, method = "buffer_overlap", buffer_m = 10)
#> <evac_route_validation>
#> Method: buffer_overlap
#>  n_modeled n_reference mean_buffer_overlap median_buffer_overlap mean_pdi
#>          1           1                 100                   100       NA
#>  median_pdi
#>          NA
```
