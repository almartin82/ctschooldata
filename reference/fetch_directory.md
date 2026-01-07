# Fetch Connecticut school directory data

Downloads and processes school directory data from the Connecticut Open
Data Portal (data.ct.gov). This includes all public educational
organizations in Connecticut with address and contact information.

## Usage

``` r
fetch_directory(tidy = TRUE, use_cache = TRUE)
```

## Arguments

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from the
  API.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download.

## Value

A tibble with school directory data. Columns include:

- `state_school_id`: State organization code (7 characters)

- `state_district_id`: District code derived from organization code

- `school_name`: Organization/school name

- `district_name`: District name

- `school_type`: Type of organization (e.g., "Elementary School")

- `grades_served`: Comma-separated list of grades offered

- `address`: Street address

- `city`: Town/city name

- `state`: State (always "CT")

- `zip`: ZIP code

- `phone`: Phone number

- `latitude`: Geographic latitude

- `longitude`: Geographic longitude

- `interdistrict_magnet`: Whether this is an interdistrict magnet

- `student_open_date`: Date the organization opened

## Details

The directory data is downloaded via the Socrata API from the CT Open
Data Portal. This data represents the official listing of all public
educational organizations in Connecticut as maintained by CSDE.

Note: This data source does not include principal/superintendent names
or email addresses. For contact information, visit EdSight Find Contacts
at https://public-edsight.ct.gov/overview/find-contacts

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data
dir_data <- fetch_directory()

# Get raw format (original API column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to elementary schools only
library(dplyr)
elementary <- dir_data |>
  filter(grepl("Elementary", school_type))

# Find all schools in Hartford
hartford_schools <- dir_data |>
  filter(grepl("Hartford", district_name))
} # }
```
