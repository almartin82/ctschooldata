# Fetch Connecticut school directory data

Downloads and processes school directory data from the Connecticut Open
Data Portal (data.ct.gov). The Education Directory contains information
about public schools, districts, and endowed academies including names,
addresses, phone numbers, grade levels served, and organization codes.

## Usage

``` r
fetch_directory(tidy = TRUE, use_cache = TRUE)
```

## Arguments

- tidy:

  If TRUE (default), returns data with standardized column names. If
  FALSE, returns raw API response format.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from API.

## Value

Data frame with directory information. If tidy=TRUE, includes columns:

- end_year:

  Always NA (directory data is current, not year-specific)

- state_school_id:

  7-digit CT organization code

- state_district_id:

  3-digit CT district code

- nces_school_id:

  Always NA (not in source)

- nces_district_id:

  Always NA (not in source)

- school_name:

  School or organization name

- district_name:

  District name

- school_type:

  Organization type (e.g., "Public Schools", "Public School Districts")

- grades_served:

  Grade span (e.g., "K-5", "9-12")

- address:

  Street address

- city:

  City/town

- state:

  Always "CT"

- zip:

  ZIP code

- phone:

  Phone number

- latitude:

  Geographic latitude (if available)

- longitude:

  Geographic longitude (if available)

- principal_name:

  Always NA (not in source)

- principal_email:

  Always NA (not in source)

- superintendent_name:

  Always NA (not in source)

- superintendent_email:

  Always NA (not in source)

## Note

The CT Open Data Education Directory does not include administrator
contact information (names, emails). These fields are included in the
output for schema compatibility but are set to NA.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get current directory data
directory <- fetch_directory()

# Get raw format
directory_raw <- fetch_directory(tidy = FALSE)

# Force fresh download
directory_fresh <- fetch_directory(use_cache = FALSE)

# Find all high schools
high_schools <- directory |>
  dplyr::filter(grepl("High School", school_name))
} # }
```
