## R CMD check results

0 errors | 0 warnings | 1 note

* checking for future file timestamps ... NOTE
  unable to verify current time

This appears to be a local check-environment issue. Two attempts to run the
remote CRAN incoming check ended before package checking because the CRAN
`archive.rds` connection failed while receiving data from the peer. The final
local `--as-cran` run therefore disabled remote incoming lookup.

## Resubmission

This version updates the existing CRAN package and addresses CRAN feedback by:

* spelling out quality assurance and quality control in DESCRIPTION;
* adding method references to DESCRIPTION using CRAN's requested DOI and URL format;
* adding small executable examples for exported functions in the Rd files;
* restoring graphical parameters after changes in the README figure script and vignette;
* adding the public GitHub repository and issue-tracker URLs;
* updating the maintainer email address to elvin.cordero@seamountgeo.com;
* exposing additional `leastcostpath` slope-surface controls;
* adding scenario comparison, bottleneck mapping, model diagnostics, and
  route-validation workflows.

## Reverse dependencies

There are no known reverse dependencies.
