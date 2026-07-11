# Example workflow

This gallery uses the packaged example data in a focused projected
window. It illustrates the package workflow and the types of layers to
inspect; it is not a finished evacuation plan or a substitute for local
review.

## Inputs and candidate exits

![Example hazard zone, roads, and escape
points](../reference/figures/readme-example-inputs.png)

Example hazard zone, roads, and escape points

The orange polygon is the land-only hazard zone used for origins and
mapped outputs. Roads are the candidate pedestrian network. Red points
are candidate escape locations found where roads cross the selected
escape boundary.

## Modeled time surface

![Example modeled evacuation
time](../reference/figures/readme-example-time.png)

Example modeled evacuation time

The time surface converts the modeled least-cost distance to safety
using the selected walking speed. It is sensitive to the elevation
surface, road mask, escape-point detection, cost function, and routing
neighbourhood.

## Reproduce the example

The figure script is packaged at `inst/scripts/make-readme-figures.R`.
It crops the elevation, hazard, and road layers before preparing tsunami
zones or running the model, then limits the display example to 500
origins and 100 escape points.

``` r

source(system.file("scripts/make-readme-figures.R", package = "evacpath"))
```

For a function-by-function inspection, see the diagnostic walkthrough in
the Examples menu.
