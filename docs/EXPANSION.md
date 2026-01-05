# Connecticut School Data Expansion Research

**Last Updated:** 2026-01-04 **Theme Researched:** Graduation Rates

## Executive Summary

Connecticut has graduation rate data available through two primary
sources: 1. **CTData.org (CKAN API)** - Accessible, but **limited to
2010-2019** and only partial district coverage 2. **EdSight (Qlik
Sense)** - Contains current data (2024-25), but requires browser
interaction for export

The primary automated source (CTData.org) stops at 2018-19, leaving a
**5+ year data gap** that would require either browser automation or
manual downloads from EdSight.

## Data Sources Found

### Source 1: CTData.org - Four Year Cohort Graduation Rates by All Students

- **URL:**
  <http://data.ctdata.org/dataset/5cef208b-b761-4d03-bf86-b8dd68d9855e/resource/494657f8-4e7c-4178-a6e9-52fef248f93f/download/fouryeargradrateallstudents2011-2019.csv>
- **HTTP Status:** 200 OK
- **Format:** CSV (properly formatted with `\n` line endings)
- **Years:** 2010-2011 through 2018-2019 (9 years)
- **Access:** Direct download via CKAN API
- **Coverage:** **INCOMPLETE** - Only 13 districts/entities (mostly
  charters, not full state)
- **Geographic Level:** District only (no school-level)
- **CRITICAL LIMITATION:** Does NOT include comprehensive district
  coverage - appears to be filtered/incomplete

### Source 2: CTData.org - Four Year Cohort Graduation Rates by Race/Ethnicity

- **URL:**
  <http://data.ctdata.org/dataset/a6ebce7b-73fa-48cd-82f4-56b7c44fbb38/resource/b92e7a91-f1ac-40a7-9d74-fa3b50dfab66/download/fouryeargradratebyraceethnicity2011-2019.csv>
- **HTTP Status:** 200 OK
- **Format:** CSV
- **Years:** 2010-2011 through 2018-2019 (9 years)
- **Access:** Direct download via CKAN API
- **Coverage:** 39 districts + state total (Connecticut)
- **Subgroups:** White, Black, Hispanic, Asian, Two or More Races
- **Geographic Level:** State and District

### Source 3: CTData.org - Four Year Cohort Graduation Rates by Gender

- **URL:**
  <http://data.ctdata.org/dataset/2d83cd5c-51ec-4182-a434-249301571ead/resource/3c7a8733-1e9d-46d4-9ab6-37345f65287c/download/fouryeargradratebygender2011-2019.csv>
- **HTTP Status:** 200 OK
- **Format:** CSV
- **Years:** 2010-2011 through 2018-2019
- **Subgroups:** Male, Female, All

### Source 4: CTData.org - Four Year Cohort Graduation Rates by Special Education Status

- **URL:**
  <http://data.ctdata.org/dataset/4c3c2ea4-381e-4115-b38f-e26b1fa94ae7/resource/bd5f3eec-9921-4e7d-b088-99cbadb0811d/download/fouryeargradratebyspecialeducationstatus2011-2019.csv>
- **HTTP Status:** 200 OK
- **Format:** CSV
- **Years:** 2010-2011 through 2018-2019
- **Subgroups:** Special Education, Not Special Education, All

### Source 5: CTData.org - Four Year Cohort Graduation Rates by ELL Status

- **URL:**
  <http://data.ctdata.org/dataset/e1cbece3-705c-4ee0-8666-606bcf100ee1/resource/838cedb0-f3d2-4659-b4d9-7aa73516b697/download/fouryeargradratebyell2011-2019.csv>
- **HTTP Status:** 200 OK
- **Format:** CSV
- **Years:** 2010-2011 through 2018-2019
- **Subgroups:** English Language Learner, Not English Language Learner,
  All

### Source 6: CTData.org - Four Year Cohort Graduation Rates by Meal Eligibility

- **URL:**
  <http://data.ctdata.org/dataset/four-year-grad-rates-by-meal-eligibility>
- **Format:** CSV
- **Years:** 2010-2011 through 2018-2019
- **Subgroups:** Eligible For Free Meal, Eligible For Reduced-Price
  Meal, Not Eligible, All

### Source 7: CTData.org - Comprehensive Graduation Rates (Older Dataset)

- **URL:**
  <http://data.ctdata.org/dataset/61b0737d-683f-48c8-8f81-7669fdbacd3e/resource/1b82d65c-5fb0-45c4-ba19-1de449cead41/download/graduationrates.csv>
- **HTTP Status:** 200 OK
- **Format:** CSV (uses `\r` for line endings - requires tr conversion)
- **Years:** 2009-2010 through 2013-2014 (5 years)
- **Coverage:** 22 districts + state total
- **Contains ALL subgroups in one file:** Race/Ethnicity, Gender,
  Special Ed, ELL, FRPM
- **LIMITATION:** Older data, ends at 2013-14

### Source 8: EdSight - Four-Year Graduation Rates (Primary State Source)

- **URL:**
  <https://public-edsight.ct.gov/performance/four-year-graduation-rates>
- **HTTP Status:** 403 Forbidden (programmatic access blocked)
- **Format:** Excel export via browser
- **Years:** Current through 2024-25
- **Coverage:** All districts and schools
- **Access:** Requires browser interaction (Qlik Sense dashboard)
- **Subgroups:** All demographics, high needs, ELL, SPED,
  race/ethnicity, gender, etc.
- **CRITICAL:** This is the authoritative source with current data

### Source 9: EdSight - Six-Year Graduation Rates

- **URL:**
  <https://public-edsight.ct.gov/performance/four-year-graduation-rates/six-year-graduation-rates>
- **HTTP Status:** 403 Forbidden
- **Format:** Excel export via browser
- **Years:** Current through 2024-25
- **Access:** Requires browser interaction

### Source 10: data.ct.gov - Next Generation Accountability System

- **URL:** <https://data.ct.gov/resource/h28j-iix5.json>
- **HTTP Status:** 200 OK
- **Format:** JSON/CSV via Socrata API
- **Years:** 2014-15 through 2022-23 (7 years available)
- **Access:** Direct API access
- **Contains:** 12 accountability indicators including chronic
  absenteeism (ind4)
- **Graduation Data:** Indicators 8 (4-year) and 9 (6-year) exist but
  rate columns are not consistently present in API data
- **Geographic Level:** District and School
- **NOTE:** Contains some graduation-related metrics but not
  comprehensive graduation rate data

### Source 11: CEDaR Data Tables (Legacy)

- **URL:** <https://sdeportal.ct.gov/Cedar/WEB/ct_report/DTHome.aspx>
- **Status:** Partially functional (JavaScript-based navigation)
- **Years:** Historical data through ~2012-13
- **Access:** Requires browser interaction
- **NOTE:** Replaced by EdSight; ZIP file downloads return 404

## Schema Analysis

### CTData.org CSV Schema (Sources 1-6)

| Column       | Type    | Description                                     |
|--------------|---------|-------------------------------------------------|
| District     | string  | District name (e.g., “Andover School District”) |
| FIPS         | string  | State FIPS code (“9” for Connecticut)           |
| Year         | string  | School year (e.g., “2018-2019”)                 |
| Variable     | string  | Metric type (see values below)                  |
| Measure Type | string  | “Number” or “Percent”                           |
| Value        | numeric | The actual value                                |

**Variable values:** - Total Cohort Count (Number) - Four Year
Graduation Count (Number) - Four Year Graduation Rate (Percent) - Still
Enrolled After Four Years Count (Number) - Still Enrolled After Four
Years Rate (Percent) - Other Count (Number) - Other Rate (Percent)

### CTData.org Comprehensive File Schema (Source 7)

| Column                                   | Type    |
|------------------------------------------|---------|
| District                                 | string  |
| FIPS                                     | string  |
| Year                                     | string  |
| Race/Ethnicity                           | string  |
| Gender                                   | string  |
| Special Education                        | string  |
| English Language Learner                 | string  |
| Eligible for Free or Reduced-price Meals | string  |
| Graduation Status                        | string  |
| Measure Type                             | string  |
| Variable                                 | string  |
| Value                                    | numeric |

**NOTE:** Uses `\r` (carriage return) for line endings instead of `\n`

### Subgroup Values

**Race/Ethnicity:** - All, White, Black, Hispanic, Asian, Native
American, Hawaiian or Pacific Islander, Two or More Races, Non Hispanic

**Gender:** - All, Male, Female

**Special Education:** - All, Special Education, Not Special Education

**English Language Learner:** - All, English Language Learner, Not
English Language Learner

**Eligible for Free or Reduced-price Meals:** - All, Eligible For Meal,
Eligible For Free Meal, Eligible For Reduced-Price Meal, Not Eligible

**Graduation Status:** - Total Cohort, Four year graduation rate, Still
enrolled after four years, Other

### Suppression Values

- `-6666`: Insufficient data / data not applicable
- `-9999`: Suppressed due to small cell size (cohort \< 6)

### ID System

- **No district codes** in CTData.org files - only district names
- State-level data uses District = “Connecticut” with FIPS = “9”
- EdSight uses organization codes (available in Education Directory)

## Known Data Issues

1.  **Line Ending Inconsistency:** Some CTData files use `\r` instead of
    `\n`
2.  **Suppression Values:** Must handle `-6666` and `-9999` as NA
3.  **Limited District Coverage:** The “All Students” file only contains
    13 districts; race/ethnicity has 39 districts
4.  **Year Gap:** CTData stops at 2018-19; current EdSight data
    (2024-25) is 5+ years newer
5.  **No School-Level Data:** CTData only provides district and state
    aggregates
6.  **No District IDs:** Must match on district name (fuzzy matching may
    be needed)

## Time Series Heuristics

Based on 2013-2014 state totals from comprehensive file:

| Metric                   | Expected Range  | Red Flag If      |
|--------------------------|-----------------|------------------|
| Total Cohort (state)     | 40,000 - 50,000 | Outside range    |
| 4-Year Grad Rate (state) | 85% - 92%       | \< 80% or \> 95% |
| Still Enrolled Rate      | 4% - 8%         | \> 10%           |
| YoY Change               | \< 2%           | \> 5% change     |

**Major Districts to Verify:** - Hartford, New Haven, Bridgeport
(urban) - Fairfield County districts (suburban) - Regional school
districts

**Verified State Values (from CTData.org):** - 2018-2019: Total cohort
~41,000-43,000 - 2018-2019: State 4-year grad rate ~87-88%

## Recommended Implementation

### Priority: MEDIUM

The data is accessible but has significant limitations.

### Complexity: MEDIUM-HARD

- API access exists for historical data
- Current data requires browser automation or manual import
- Multiple files must be merged for complete subgroup coverage

### Estimated Files to Modify: 4-5

### Implementation Approach

**Option A: CTData.org Only (Historical Data)** - Pros: Fully
automatable, API access works - Cons: Data ends at 2018-19, incomplete
district coverage

**Option B: EdSight + Browser Automation** - Pros: Current data,
complete coverage - Cons: Requires Playwright/Selenium, may break if UI
changes

**Option C: Hybrid Approach (Recommended)** 1. Implement CTData.org for
2010-2019 historical data 2. Add `import_local_grad()` for manually
downloaded EdSight exports 3. Future: Add browser automation for EdSight
when resources allow

### Implementation Steps

1.  Create `get_ctdata_graduation()` internal function to fetch from
    CKAN API
2.  Create `process_grad()` to standardize column names and handle
    suppressions
3.  Create `tidy_grad()` to pivot to long format
4.  Create `fetch_grad(end_year, tidy=TRUE)` public function
5.  Create `import_local_grad()` for EdSight Excel imports
6.  Add tests for raw data fidelity

### Required Dependencies

- httr (already in package)
- jsonlite (already in package)
- readr (already in package)

## Test Requirements

### Raw Data Fidelity Tests Needed

**From CTData.org race/ethnicity file (verified values):** - 2018-2019:
State total White cohort = 23,742 - 2018-2019: State White graduation
count = 22,158 - 2013-2014: State total cohort = 43,050 - 2013-2014:
State graduation rate (all) = 87%

**District-level verification:** - 2018-2019: Hartford - verify cohort
count and grad rate match source - 2018-2019: Bridgeport - verify
against source

### Data Quality Checks

- All graduation rates between 0 and 100
- Total cohort \> graduation count
- Graduation + Still Enrolled + Other = Total Cohort (approximately)
- No negative values (after handling suppressions)
- State total should be sum of subgroups (within tolerance)

## Alternative Approaches Considered

### NOT RECOMMENDED: NCES/Federal Data

Federal sources aggregate state data differently and lose
Connecticut-specific details. NEVER use as primary source per project
rules.

### POSSIBLE: CEDaR Direct Access

CEDaR has graduation data tables but requires JavaScript navigation. The
legacy ZIP downloads now return 404. Could potentially be scraped but
EdSight is the authoritative replacement.

### POSSIBLE: Socrata API for Accountability Data

The Next Generation Accountability System dataset on data.ct.gov
contains some graduation indicators but is missing the comprehensive
graduation rate breakdowns needed.

## Next Steps After Implementation

1.  Monitor CTData.org for updates beyond 2018-19
2.  Consider Playwright automation for EdSight when 2019-2024 gap needs
    to be filled
3.  Add six-year graduation rate support
4.  Add school-level data when available via API

------------------------------------------------------------------------

## CKAN API Reference

Base URL: `http://data.ctdata.org/api/3/action/`

**Package Search:**

    GET /package_search?q=graduation

**Package Show:**

    GET /package_show?id=four-year-grad-rates-by-all-students

**Direct CSV Downloads:**

``` r
# All students
"http://data.ctdata.org/dataset/5cef208b-b761-4d03-bf86-b8dd68d9855e/resource/494657f8-4e7c-4178-a6e9-52fef248f93f/download/fouryeargradrateallstudents2011-2019.csv"

# By race/ethnicity
"http://data.ctdata.org/dataset/a6ebce7b-73fa-48cd-82f4-56b7c44fbb38/resource/b92e7a91-f1ac-40a7-9d74-fa3b50dfab66/download/fouryeargradratebyraceethnicity2011-2019.csv"

# By gender
"http://data.ctdata.org/dataset/2d83cd5c-51ec-4182-a434-249301571ead/resource/3c7a8733-1e9d-46d4-9ab6-37345f65287c/download/fouryeargradratebygender2011-2019.csv"

# By special education
"http://data.ctdata.org/dataset/4c3c2ea4-381e-4115-b38f-e26b1fa94ae7/resource/bd5f3eec-9921-4e7d-b088-99cbadb0811d/download/fouryeargradratebyspecialeducationstatus2011-2019.csv"

# By ELL
"http://data.ctdata.org/dataset/e1cbece3-705c-4ee0-8666-606bcf100ee1/resource/838cedb0-f3d2-4659-b4d9-7aa73516b697/download/fouryeargradratebyell2011-2019.csv"
```
