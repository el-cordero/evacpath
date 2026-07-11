# Create a slope-based conductance surface

Masks a DEM to an optional road/pathway mask and creates a slope
conductance surface using `leastcostpath`.

## Usage

``` r
make_conductance_surface(
  dem,
  road_mask = NULL,
  resolution = NULL,
  method = "slope",
  lcp_cost_function = "tobler",
  lcp_neighbours = 16,
  lcp_crit_slope = 12,
  lcp_max_slope = NULL,
  ...
)
```

## Arguments

- dem:

  Elevation raster.

- road_mask:

  Optional road/pathway mask.

- resolution:

  Optional target DEM resolution before conductance creation.

- method:

  Conductance method. Currently only `"slope"` is implemented.

- lcp_cost_function:

  Character string or function passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).

- lcp_neighbours:

  Neighbourhood passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).
  Use `4`, `8`, `16`, `32`, `48`, or a custom matrix accepted by
  `leastcostpath`.

- lcp_crit_slope:

  Numeric critical slope passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).

- lcp_max_slope:

  Optional numeric maximum slope passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html).

- ...:

  Additional named arguments passed to
  [`leastcostpath::create_slope_cs()`](https://rdrr.io/pkg/leastcostpath/man/create_slope_cs.html),
  such as `exaggeration`.

## Value

A `leastcostpath` conductance surface object.

## Examples

``` r
dem <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 5,
  vals = 1, crs = "EPSG:3857")
make_conductance_surface(dem, lcp_neighbours = 8)
#> calculating slope...
#> Applying tobler cost function
#> Class:  conductanceMatrix
#> cost function:  tobler
#> neighbours: 8
#> resolution: 1 1 (x, y)
#> max slope: NA
#> exaggeration: FALSE
#> critical slope: NA
#> SpatRaster dimenions:  5 5 25 (nrow, ncol, ncell)
#> Matrix dimensions:  25 25 (nrow, ncol)
#> crs: +proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs
#> extent: 0 5 0 5 (xmin, xmax, ymin, ymax)
```
