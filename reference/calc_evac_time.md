# Convert distance to evacuation time

Convert distance to evacuation time

## Usage

``` r
calc_evac_time(distance_m, walking_speed_mps = 1.22, units = "minutes")
```

## Arguments

- distance_m:

  Distance in meters.

- walking_speed_mps:

  Walking speed in meters per second. The paper-style default is 1.22
  m/s, but this should be changed for local planning scenarios.

- units:

  Output units: `"minutes"`, `"seconds"`, or `"hours"`.

## Value

Numeric vector of evacuation times.

## Examples

``` r
calc_evac_time(c(0, 120, 240), walking_speed_mps = 1.2)
#> [1] 0.000000 1.666667 3.333333
```
