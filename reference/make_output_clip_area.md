# Make an output clip area for evacuation polygons

Make an output clip area for evacuation polygons

## Usage

``` r
make_output_clip_area(
  hazard_zone,
  roads_buffer,
  final_road_buffer_m = 3,
  clip_mode = c("hazard", "road_hazard", "hazard_plus_roads", "none")
)
```

## Arguments

- hazard_zone:

  Hazard zone polygon.

- roads_buffer:

  Buffered roads.

- final_road_buffer_m:

  Additional road buffer for output clipping.

- clip_mode:

  One of `"hazard"`, `"road_hazard"`, `"hazard_plus_roads"`, or
  `"none"`.

## Value

A `SpatVector` clip area or `NULL`.
