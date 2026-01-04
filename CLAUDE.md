## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---


# Claude Code Instructions

### GIT COMMIT POLICY
- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pyctschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pyctschooldata && pytest tests/test_pyctschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pyctschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

# ctschooldata Package Documentation

## Package Overview

`ctschooldata` provides R functions for fetching Connecticut public school enrollment data from the Connecticut State Department of Education (CSDE).

**Current Status**: WORKS_MOSTLY - The package structure is complete but the automated data source provides limited data (see Known Issues below).

## Data Sources

### Primary Source: EdSight (Requires Manual Export)
- **URL**: https://public-edsight.ct.gov/Students/Enrollment-Dashboard
- **Export URL**: https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Public-School-Enrollment-Export
- **Technology**: Qlik Sense (requires browser interaction)
- **Data Available**: 2007-2024 (end years)
- **Includes**: Full enrollment counts, demographics, special populations, grade levels
- **Limitation**: No direct API access; requires manual browser export

### Automated Source: CT Open Data Education Directory
- **URL**: https://data.ct.gov/resource/9k2y-kqxn.json
- **Dataset ID**: 9k2y-kqxn
- **Data Available**: Current year only (organization list)
- **Includes**: District/school names, organization codes, grade-level offerings
- **CRITICAL LIMITATION**: Contains binary flags (0/1) for grade offerings, NOT enrollment counts

### Secondary Source: CTData.org
- **URL**: http://data.ctdata.org/dataset/student-enrollment-by-grade
- **Data Available**: 2007-2021 (limited coverage, only ~4 charter districts)
- **Not comprehensive**: Does not include all CT districts

## Available Years

```r
get_available_years()  # Returns 2007:2024
```

- **2007-2024**: Available via EdSight (manual export required)
- **2025+**: Data may exist but not yet confirmed

## Available Subgroups

When using EdSight data (manual export), these subgroups are available:
- **Demographics**: white, black, hispanic, asian, american_indian, pacific_islander, two_or_more
- **Special Populations**: lep (ELL), econ_disadv, special_ed
- **Grade Levels**: PK, K, 01-12, TOTAL

**Current automated data only provides**: total_enrollment (as binary grade flags)

## Known Issues

### CRITICAL: Automated Data Source Provides Binary Flags, Not Counts

The Education Directory API (`9k2y-kqxn`) that the package can access automatically contains:
- **Binary flags (0 or 1)** indicating whether a school offers a grade
- **NOT actual enrollment counts**

When you see n_students values of 0 or 1, this indicates the package is using the Education Directory source.

### No State-Level Aggregates

The automated data source does not include a state-level aggregate row. `is_state` will always be FALSE.

### No Demographic Subgroups

The automated data source only includes `total_enrollment` subgroup (which is actually grade-offering flags). Race/ethnicity and special population data requires EdSight export.

## Data Fidelity Requirement

**CRITICAL**: The tidy=TRUE version MUST maintain fidelity to the raw, unprocessed source file. Every test should verify actual values from the raw data appear correctly in the tidied output.

When implementing fixes or improvements:
1. Always compare tidied output against raw source
2. Preserve exact district/school names from source
3. Preserve organization codes exactly as provided
4. Document any transformations applied to enrollment counts

## Fixing the Data Source

To get real enrollment data into this package, implement one of these approaches:

### Option 1: Manual Import (Current Workaround)
1. Visit https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Public-School-Enrollment-Export
2. Export data for desired years
3. Use `import_local_enr()` to import the downloaded file

```r
# Example usage
enr_2024 <- import_local_enr("~/Downloads/CT_Enrollment_2023-24.xlsx", end_year = 2024)
```

### Option 2: Browser Automation
Implement Playwright/Selenium automation to:
1. Navigate to EdSight enrollment export
2. Select filters (year, format)
3. Trigger export and capture downloaded file
4. Process the downloaded data

### Option 3: Find Alternative API
Research if:
- EdSight has an undocumented API endpoint
- CT Open Data portal has additional enrollment datasets
- CTData.org has more comprehensive data

## File Structure

```
ctschooldata/
  R/
    fetch_enrollment.R   # Main fetch functions (fetch_enr, fetch_enr_multi)
    get_raw_enrollment.R # Raw data download functions
    process_enrollment.R # Data processing and standardization
    tidy_enrollment.R    # Wide-to-long transformation
    cache.R              # Local caching functions
    utils.R              # Helper utilities
  tests/
    testthat/
      test-enrollment-data.R  # Comprehensive data tests (documents known issues)
      test-fetch.R            # Function interface tests
      test-utils.R            # Utility function tests
      test-cache.R            # Cache function tests
```

## Key Functions

| Function | Purpose | Notes |
|----------|---------|-------|
| `fetch_enr(end_year)` | Fetch enrollment for one year | Returns binary flags without EdSight data |
| `fetch_enr_multi(years)` | Fetch multiple years | Combines results |
| `import_local_enr(path, year)` | Import local file | Use for EdSight exports |
| `get_available_years()` | Get year range | Returns 2007:2024 |
| `tidy_enr(df)` | Wide to long format | Transforms subgroups |
| `clear_cache()` | Clear cached data | Useful for re-downloading |

## Testing

Run tests with:
```r
devtools::test()
```

Current tests document known issues with message output explaining limitations.


---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.


---

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with auto-merge:

```bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

```bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass:
- R-CMD-check (0 errors, 0 warnings)
- Python tests (if py{st}schooldata exists)
- pkgdown build (vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks pass.


---

## README Images from Vignettes (REQUIRED)

**NEVER use `man/figures/` or `generate_readme_figs.R` for README images.**

README images MUST come from pkgdown-generated vignette output so they auto-update on merge:

```markdown
![Chart name](https://almartin82.github.io/{package}/articles/{vignette}_files/figure-html/{chunk-name}-1.png)
```

**Why:** Vignette figures regenerate automatically when pkgdown builds. Manual `man/figures/` requires running a separate script and is easy to forget, causing stale/broken images.
