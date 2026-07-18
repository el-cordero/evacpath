# Contributing to evacpath

Thanks for helping improve `evacpath`. Contributions that make
evacuation workflows clearer, more reproducible, and easier to review
are especially welcome.

## Before opening a change

1.  Open an issue first for a proposed feature, scientific-method
    change, or substantial documentation revision.
2.  Keep pull requests focused. Do not combine behavior changes,
    reformatting, generated files, and unrelated refactoring in one
    change.
3.  Preserve the package’s place-agnostic design. Region-specific data
    preparation belongs in an example, article, or downstream project
    unless it is broadly reusable.

## Development checks

Use a recent R release and install the development dependencies:

``` r

devtools::document()
devtools::test(stop_on_failure = TRUE)
devtools::check(args = "--as-cran")
```

When changing a vignette or pkgdown page, also rebuild the articles
locally:

``` r

pkgdown::build_site(new_process = FALSE, install = TRUE)
```

## Scientific and spatial review

Document units, coordinate reference systems, elevation conventions,
routing assumptions, and interpretation limits. Do not present a modeled
route, travel time, or corridor as observed behavior or an approved
evacuation plan without independent evidence.

## Reporting concerns

Please follow the [Code of
Conduct](https://github.com/el-cordero/evacpath/blob/main/CODE_OF_CONDUCT.md).
Security-sensitive reports should follow the [Security
Policy](https://github.com/el-cordero/evacpath/blob/main/SECURITY.md).
