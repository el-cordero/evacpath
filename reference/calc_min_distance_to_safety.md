# Calculate minimum least-cost distance from origins to safety

For each origin point, calculates least-cost paths to all candidate
safety points and stores the shortest finite path distance. Destination
points are appended to the output with distance equal to zero.

## Usage

``` r
calc_min_distance_to_safety(
  cs,
  origins,
  destinations,
  include_destinations = TRUE,
  progress = FALSE,
  progress_every = 1L,
  check_locations = FALSE,
  return_routes = FALSE
)
```

## Arguments

- cs:

  A `leastcostpath` conductance surface.

- origins:

  Origin points.

- destinations:

  Escape/safety destination points.

- include_destinations:

  Logical. Add destination points with distance = 0.

- progress:

  Logical. Print simple progress messages.

- progress_every:

  Integer. Print progress every `n` origins when `progress = TRUE`.

- check_locations:

  Logical passed to
  [`leastcostpath::create_lcp()`](https://rdrr.io/pkg/leastcostpath/man/create_lcp.html).
  The default is `FALSE` for speed after inputs have already been
  projected and cropped.

- return_routes:

  Logical. If `TRUE`, return the selected shortest route for each
  reachable origin alongside the distance points. The default is `FALSE`
  to preserve the original return type and avoid storing route
  geometries when they are not needed.

## Value

A point `SpatVector` with columns `distance` and `type`. When
`return_routes = TRUE`, returns a list with `distance_points`, `routes`,
and `unreachable_origins`.

## Examples

``` r
dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
  vals = 1, crs = "EPSG:3857")
cs <- make_conductance_surface(dem)
#> calculating slope...
#> Applying tobler cost function
origins <- terra::vect(data.frame(x = 0.5, y = 0.5), geom = c("x", "y"), crs = "EPSG:3857")
destinations <- terra::vect(data.frame(x = 4.5, y = 4.5), geom = c("x", "y"), crs = "EPSG:3857")
calc_min_distance_to_safety(cs, origins, destinations)
#> class       : SpatVector
#> geometry    : points
#> dimensions  : 2, 2  (geometries, attributes)
#> extent      : 0.5, 4.5, 0.5, 4.5  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Pseudo-Mercator
#> names       : distance   type
#> type        :    <num>  <chr>
#> values      :  5.65685   road
#>                      0 escape
```
