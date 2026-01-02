# TODO: pkgdown build issues

## Issue: Network timeout during pkgdown build

**Date:** 2026-01-01

**Error:** The pkgdown build fails with a network timeout when trying to check CRAN/Bioconductor for package availability:

```
Error:
! in callr subprocess.
Caused by error in `httr2::req_perform(req)`:
! Failed to perform HTTP request.
Caused by error in `curl::curl_fetch_memory()`:
! Timeout was reached [cloud.r-project.org]:
Connection timed out after 10002 milliseconds
```

**Stack trace shows:**
- `pkgdown:::cran_link(pkg$package)` is making a network request
- The request times out after 10 seconds

**Notes:**
- This is a network connectivity issue, not a code/data problem
- The vignette (`vignettes/enrollment_hooks.Rmd`) was not even reached before the build failed
- Retry when network connectivity to cloud.r-project.org is stable
- Consider adding `cran: null` to `_pkgdown.yml` to skip CRAN link check if this persists
