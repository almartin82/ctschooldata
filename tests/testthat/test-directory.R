# ==============================================================================
# School Directory Tests for ctschooldata
# ==============================================================================
#
# Tests for fetch_directory() function that downloads school/district data
# from the Connecticut Open Data Portal (data.ct.gov)
#
# ==============================================================================

library(testthat)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("CT Open Data Education Directory API is accessible", {
  skip_if_offline()
  skip_on_cran()

  url <- "https://data.ct.gov/resource/9k2y-kqxn.json?$limit=1"

  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200,
               info = "CT Open Data API should return HTTP 200")
})

# ==============================================================================
# STEP 2: API Data Download Tests
# ==============================================================================

test_that("Can download directory data from CT Open Data API", {
  skip_if_offline()
  skip_on_cran()

  url <- "https://data.ct.gov/resource/9k2y-kqxn.json?$limit=10"

  response <- httr::GET(url, httr::timeout(60))

  expect_equal(httr::status_code(response), 200)

  content <- httr::content(response, as = "text", encoding = "UTF-8")
  expect_true(nchar(content) > 0)

  # Parse JSON
  data <- jsonlite::fromJSON(content, flatten = TRUE)
  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 0)
})

# ==============================================================================
# STEP 3: Column Structure Tests
# ==============================================================================

test_that("Raw directory data has expected columns", {
  skip_if_offline()
  skip_on_cran()

  raw <- get_raw_directory()

  expect_true(is.data.frame(raw))
  expect_gt(nrow(raw), 100)  # Should have at least 100 schools/districts

  # Check for key columns
  expected_cols <- c("organization_code", "name", "district_name",
                     "organization_type", "address", "town", "zipcode")

  for (col in expected_cols) {
    expect_true(col %in% names(raw),
                info = paste("Raw data should have column:", col))
  }
})

# ==============================================================================
# STEP 4: fetch_directory() Function Tests
# ==============================================================================

test_that("fetch_directory() returns standardized schema", {
  skip_if_offline()
  skip_on_cran()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  expect_true(is.data.frame(dir_data))
  expect_s3_class(dir_data, "tbl_df")
  expect_gt(nrow(dir_data), 100)

  # Check for standard columns
  expected_cols <- c("state_school_id", "state_district_id", "school_name",
                     "district_name", "school_type", "grades_served",
                     "address", "city", "state", "zip", "phone")

  for (col in expected_cols) {
    expect_true(col %in% names(dir_data),
                info = paste("Tidy data should have column:", col))
  }

  # State should always be "CT"
  expect_true(all(dir_data$state == "CT", na.rm = TRUE))
})

test_that("fetch_directory() with tidy=FALSE returns raw format", {
  skip_if_offline()
  skip_on_cran()

  dir_raw <- fetch_directory(tidy = FALSE, use_cache = FALSE)

  expect_true(is.data.frame(dir_raw))
  expect_gt(nrow(dir_raw), 100)

  # Should have original API column names
  expect_true("organization_code" %in% names(dir_raw))
  expect_true("name" %in% names(dir_raw))
})

# ==============================================================================
# STEP 5: Data Quality Tests
# ==============================================================================

test_that("Organization codes are properly formatted", {
  skip_if_offline()
  skip_on_cran()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # Organization codes should be 7 characters with leading zeros preserved
  expect_true(all(nchar(dir_data$state_school_id) == 7, na.rm = TRUE),
              info = "All organization codes should be 7 characters")

  # District codes should be 3 characters
  expect_true(all(nchar(dir_data$state_district_id) == 3, na.rm = TRUE),
              info = "All district codes should be 3 characters")
})

test_that("School names and district names are non-empty", {
  skip_if_offline()
  skip_on_cran()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # School names should not be empty
  expect_true(all(nchar(trimws(dir_data$school_name)) > 0, na.rm = TRUE),
              info = "School names should not be empty")

  # District names should not be empty
  expect_true(all(nchar(trimws(dir_data$district_name)) > 0, na.rm = TRUE),
              info = "District names should not be empty")
})

test_that("Latitude and longitude are valid coordinates", {
  skip_if_offline()
  skip_on_cran()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # Filter to records with coordinates
  with_coords <- dir_data[!is.na(dir_data$latitude) & !is.na(dir_data$longitude), ]

  if (nrow(with_coords) > 0) {
    # Connecticut latitude range: approximately 41-42°N
    expect_true(all(with_coords$latitude >= 40.9 & with_coords$latitude <= 42.1),
                info = "Latitudes should be in Connecticut range")

    # Connecticut longitude range: approximately -73 to -71°W
    expect_true(all(with_coords$longitude >= -73.8 & with_coords$longitude <= -71.7),
                info = "Longitudes should be in Connecticut range")
  }
})

# ==============================================================================
# STEP 6: Cache Tests
# ==============================================================================

test_that("Directory caching works correctly", {
  skip_if_offline()
  skip_on_cran()

  # Clear cache first
  clear_directory_cache()

  # First call should download
  dir_data1 <- fetch_directory(tidy = TRUE, use_cache = TRUE)
  expect_gt(nrow(dir_data1), 100)

  # Second call should use cache
  dir_data2 <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Should be identical
  expect_equal(nrow(dir_data1), nrow(dir_data2))
  expect_equal(names(dir_data1), names(dir_data2))

  # Clean up
  clear_directory_cache()
})

# ==============================================================================
# STEP 7: Integration with TODO.md Schema
# ==============================================================================

test_that("fetch_directory() returns columns matching TODO.md target schema", {
  skip_if_offline()
  skip_on_cran()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # Target schema from TODO.md (excluding NCES IDs which CT doesn't have in this source)
  # end_year is not applicable for directory data
  target_cols <- c("state_school_id", "state_district_id",
                   "school_name", "district_name", "school_type",
                   "grades_served", "address", "city", "state", "zip", "phone",
                   "principal_name", "principal_email",
                   "superintendent_name", "superintendent_email")

  for (col in target_cols) {
    expect_true(col %in% names(dir_data),
                info = paste("Should have target schema column:", col))
  }

  # Note: CT Open Data source does not include contact names/emails
  # These are set to NA in the implementation
})

test_that("Contact fields are present but NA (not in data source)", {
  skip_if_offline()
  skip_on_cran()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # CT Open Data doesn't include contact info
  # Fields should exist but be NA
  expect_true("principal_name" %in% names(dir_data))
  expect_true("principal_email" %in% names(dir_data))
  expect_true("superintendent_name" %in% names(dir_data))
  expect_true("superintendent_email" %in% names(dir_data))

  # All should be NA
  expect_true(all(is.na(dir_data$principal_name)))
  expect_true(all(is.na(dir_data$principal_email)))
  expect_true(all(is.na(dir_data$superintendent_name)))
  expect_true(all(is.na(dir_data$superintendent_email)))
})
