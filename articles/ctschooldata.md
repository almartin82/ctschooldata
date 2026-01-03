# Getting Started with ctschooldata

## Overview

The `ctschooldata` package provides tools for accessing Connecticut
public school enrollment data from the Connecticut State Department of
Education (CSDE).

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/ctschooldata")
```

## Quick Start

### Basic Usage

``` r
library(ctschooldata)
library(dplyr)

# Check available years
years <- get_available_years()
print(years)
# [1] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024

# Fetch enrollment data for a single year
enr_2015 <- fetch_enr(2015)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2010:2015)
```

### Understanding the Data Structure

The package returns tidy data frames with the following key columns:

| Column          | Description                                         |
|-----------------|-----------------------------------------------------|
| `end_year`      | School year end (e.g., 2024 for 2023-24)            |
| `type`          | Organization type: “State”, “District”, or “Campus” |
| `district_name` | Name of the school district                         |
| `campus_name`   | Name of the school (if campus-level)                |
| `org_code`      | Connecticut organization code                       |
| `grade_level`   | Grade level (PK, K, 01-12, TOTAL)                   |
| `subgroup`      | Demographic subgroup                                |
| `n_students`    | Enrollment count                                    |
| `is_state`      | TRUE if state-level aggregate                       |
| `is_district`   | TRUE if district-level                              |
| `is_campus`     | TRUE if school-level                                |

### Filtering Data

``` r
# District totals
district_totals <- enr_2015 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students))

# Grade-level enrollment for a specific district
district_grades <- enr_2015 |>
  filter(district_name == "Achievement First Bridgeport Academy Inc",
         subgroup == "total_enrollment",
         grade_level != "TOTAL")
```

## Data Sources

The package uses multiple data sources depending on the year:

### CTData.org (Years 2007-2016)

For years 2007-2016, the package fetches actual enrollment counts from
CTData.org. This data includes:

- **District-level enrollment** by grade
- **Approximately 6 sample districts** (not all CT districts)
- **Actual student counts** (not binary flags)

``` r
# Fetch historical data with real enrollment counts
enr_2015 <- fetch_enr(2015)

# Check a specific district's enrollment
enr_2015 |>
  filter(district_name == "Achievement First Bridgeport Academy Inc",
         grade_level == "TOTAL") |>
  select(district_name, grade_level, n_students)
```

### CT Open Data Education Directory (Years 2017+)

For years 2017 and later, the package falls back to the CT Open Data
Education Directory. **Important limitations:**

- Contains **binary flags (0/1)** indicating whether a school offers a
  grade
- Does **NOT** contain actual enrollment counts
- Covers **all CT schools and districts**

``` r
# Check if data contains binary flags
enr_2024 <- fetch_enr(2024)
max(enr_2024$n_students, na.rm = TRUE)  # Will be 1 if binary flags
```

### EdSight Exports (Manual)

For complete enrollment data (any year), you can manually export from
EdSight:

1.  Visit:
    <https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Public-School-Enrollment-Export>
2.  Select your desired year and filters
3.  Export to Excel
4.  Import using
    [`import_local_enr()`](https://almartin82.github.io/ctschooldata/reference/import_local_enr.md):

``` r
# Import manually downloaded EdSight data
enr_2024 <- import_local_enr(
  "~/Downloads/CT_Enrollment_2023-24.xlsx",
  end_year = 2024
)

# Data is cached for future use
enr_2024 <- fetch_enr(2024)  # Uses cached data
```

## Data Quality Notes

### Suppression Markers

Connecticut uses various suppression markers for small cell sizes:

- Text markers: `*`, `***`, `N/A`, `<5`, `<10`
- Numeric codes: `-9999`, `-6666`

The package automatically converts these to `NA`:

``` r
# Suppression markers are converted to NA
safe_numeric("-9999")  # Returns NA
safe_numeric("<5")     # Returns NA
safe_numeric("*")      # Returns NA
```

### Checking Data Quality

``` r
# Check if data has actual enrollment counts
enr <- fetch_enr(2015)

# Real enrollment data has max > 1
max_val <- max(enr$n_students, na.rm = TRUE)
if (max_val > 1) {
  message("Data contains actual enrollment counts")
} else {
  message("Data contains binary grade-offering flags only")
}

# Check for any remaining negative values (should be none)
neg_count <- sum(enr$n_students < 0, na.rm = TRUE)
stopifnot(neg_count == 0)
```

### Year-Specific Recommendations

| Years     | Data Source         | Contains Actual Counts? | Coverage            |
|-----------|---------------------|-------------------------|---------------------|
| 2007-2016 | CTData.org          | Yes                     | ~6 sample districts |
| 2017+     | Education Directory | No (binary flags)       | All districts       |
| Any       | EdSight Export      | Yes                     | Full state          |

## Cache Management

``` r
# View cache status
cache_status()

# Clear all cached data
clear_cache()

# Clear specific year
clear_cache(2024)
```

## Available Functions

| Function                                                                                              | Description                         |
|-------------------------------------------------------------------------------------------------------|-------------------------------------|
| `fetch_enr(end_year)`                                                                                 | Fetch enrollment for one year       |
| `fetch_enr_multi(years)`                                                                              | Fetch enrollment for multiple years |
| `import_local_enr(path, year)`                                                                        | Import locally downloaded file      |
| [`get_available_years()`](https://almartin82.github.io/ctschooldata/reference/get_available_years.md) | Get range of available years        |
| `tidy_enr(df)`                                                                                        | Convert wide data to tidy format    |
| `id_enr_aggs(df)`                                                                                     | Add aggregation level flags         |
| `enr_grade_aggs(df)`                                                                                  | Create K-8, HS, K-12 aggregates     |
| [`clear_cache()`](https://almartin82.github.io/ctschooldata/reference/clear_cache.md)                 | Clear cached data                   |
| [`cache_status()`](https://almartin82.github.io/ctschooldata/reference/cache_status.md)               | Show cached files                   |

## Year Convention

The package uses **end year** convention: - `end_year = 2024` means the
**2023-24** school year - `end_year = 2025` means the **2024-25** school
year

``` r
# 2023-24 school year
enr_2024 <- fetch_enr(2024)

# Format for display
format_school_year(2024)  # Returns "2023-24"

# Parse from display format
parse_school_year("2023-24")  # Returns 2024
```

## Known Limitations

1.  **No state-level aggregates**: The automated sources do not include
    state-wide totals. Calculate these manually if needed.

2.  **Limited district coverage (2007-2016)**: CTData.org only includes
    approximately 6 sample districts, not all CT districts.

3.  **Binary flags (2017+)**: The Education Directory only indicates
    grade offerings, not actual enrollment counts.

4.  **No demographic breakdowns**: Race/ethnicity, ELL, and special
    education data requires manual EdSight export.

## Further Resources

- [EdSight Portal](https://public-edsight.ct.gov/)
- [CT Open Data](https://data.ct.gov/)
- [CTData.org](http://data.ctdata.org/)
- [Connecticut State Department of Education](https://portal.ct.gov/sde)

## Python Support

A Python wrapper is also available:

``` python
import pyctschooldata as ct

# Fetch data
enr = ct.fetch_enr(2015)

# Get available years
years = ct.get_available_years()
print(f"Data available: {years['min_year']}-{years['max_year']}")
```
