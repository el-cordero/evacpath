# Calculate the minimum path distance from a list of least-cost paths

Calculate the minimum path distance from a list of least-cost paths

## Usage

``` r
calculate_min_dist(lc_paths_list)
```

## Arguments

- lc_paths_list:

  A list of least-cost path line vectors.

## Value

Minimum non-zero, finite path distance.

## Examples

``` r
line <- terra::vect(matrix(c(0, 0, 1, 1), ncol = 2, byrow = TRUE),
  type = "lines", crs = "EPSG:3857")
calculate_min_dist(list(line))
#> [1] 1.414214
```
