## R CMD check results

0 errors | 0 warnings | 1 note

* `R CMD check --as-cran evacpath_0.2.0.tar.gz` (2026-07-17) completed with
  one incoming-feasibility NOTE. It records the maintainer email change from
  elvin.cordero1@upr.edu to elvin.cordero@seamountgeo.com and reports four
  README policy URLs as 404 because their new target files are local and have
  not yet been pushed to the public GitHub repository. The package check is
  otherwise clean.

## Release candidate verification

* Source archive: `evacpath_0.2.0.tar.gz` (4.8 MB).
  SHA-256: `46a8423035e6ed12dc98aa4bb9e5c58e6b1a0f77b6b497500a13da677b170082`.
* `devtools::test(stop_on_failure = TRUE)`: 66 passing tests.
* Vignettes and pkgdown site build successfully.
* `inst/scripts/audit-release-uris.R evacpath_0.2.0.tar.gz`: 745 local links
  checked; no unresolved local targets or `file://` URLs.
* External URL validation reached GitHub successfully. The four new policy URLs
  are the only invalid external links and will resolve after the policy files
  are pushed to the public repository.

## Resubmission

This version updates the existing CRAN package and addresses CRAN feedback by:

* spelling out quality assurance and quality control in DESCRIPTION;
* adding method references to DESCRIPTION using CRAN's requested DOI and URL format;
* adding small executable examples for exported functions in the Rd files;
* restoring graphical parameters after changes in the README figure script and vignette;
* adding the public GitHub repository and issue-tracker URLs;
* adding a public pkgdown documentation site;
* updating the maintainer email address to elvin.cordero@seamountgeo.com;
* exposing additional `leastcostpath` slope-surface controls;
* adding scenario comparison, bottleneck mapping, model diagnostics, and
  route-validation workflows.

## Reverse dependencies

There are no known reverse dependencies.
