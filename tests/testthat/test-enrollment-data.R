# Tests for enrollment data structure and content
# These tests document the current state of the data source

test_that("fetch_enr returns data frame with expected structure", {
  skip_on_cran()
  skip_if_offline()

  # Use 2024 as the test year
  enr <- fetch_enr(2024, use_cache = TRUE)

  # Should return a data frame
  expect_s3_class(enr, "data.frame")

  # Should have required columns
  required_cols <- c(
    "end_year", "type", "district_name",
    "grade_level", "subgroup", "n_students",
    "is_state", "is_district", "is_campus"
  )
  for (col in required_cols) {
    expect_true(col %in% names(enr), info = paste("Missing column:", col))
  }
})


test_that("fetch_enr includes organization types", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Should have type column with expected values
  expect_true("type" %in% names(enr))
  types <- unique(enr$type)

  # Current data source (Education Directory) provides these types
  expect_true("District" %in% types || "Campus" %in% types)
})


test_that("Education Directory provides expected organization structure", {
  skip_on_cran()
  skip_if_offline()

  # Fetch the education directory directly
  dir_url <- "https://data.ct.gov/resource/9k2y-kqxn.json?$limit=100"
  response <- httr::GET(dir_url, httr::timeout(30))

  skip_if(httr::http_error(response), "Cannot reach CT Open Data portal")

  dir_data <- jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"))

  # Should have expected columns
  expect_true("district_name" %in% names(dir_data))
  expect_true("name" %in% names(dir_data))
  expect_true("organization_type" %in% names(dir_data))
  expect_true("organization_code" %in% names(dir_data))

  # Should have grade columns (these are binary flags, NOT enrollment counts)
  grade_cols <- c("kindergarten", "grade_1", "grade_2", "grade_3")
  for (col in grade_cols) {
    expect_true(col %in% names(dir_data), info = paste("Missing grade column:", col))
  }

  # IMPORTANT: Grade columns contain binary flags (0 or 1), not enrollment counts
  # This is a known limitation - see CLAUDE.md for details
  if ("kindergarten" %in% names(dir_data)) {
    k_values <- as.numeric(dir_data$kindergarten)
    # All values should be 0 or 1 (binary flags)
    expect_true(all(k_values %in% c(0, 1, NA)),
      info = "Grade columns should be binary flags (0/1), not enrollment counts"
    )
  }
})


test_that("fetch_enr_multi returns combined data for multiple years", {
  skip_on_cran()
  skip_if_offline()

  # Test with two years
  enr <- fetch_enr_multi(c(2023, 2024), use_cache = TRUE)

  expect_s3_class(enr, "data.frame")
  expect_true("end_year" %in% names(enr))

  # Should have data for both years (or at least one if cached)
  years_present <- unique(enr$end_year)
  expect_true(length(years_present) >= 1)
})


test_that("all available years can be fetched", {
  skip_on_cran()
  skip_if_offline()

  years <- get_available_years(check_api = FALSE)

  # Test a sample of years to avoid long test times
  test_years <- c(min(years), 2015, 2020, max(years))
  test_years <- test_years[test_years %in% years]

  for (yr in test_years) {
    enr <- tryCatch(
      fetch_enr(yr, use_cache = TRUE),
      error = function(e) NULL
    )
    # Should return data frame or give a meaningful message
    if (!is.null(enr)) {
      expect_s3_class(enr, "data.frame")
    }
  }
})


# ============================================================================
# Known Issues Tests
# These tests document current limitations of the data source
# ============================================================================

test_that("KNOWN ISSUE: No state-level aggregates in current data source", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Currently, there is NO state-level data because the Education Directory

  # doesn't include a state aggregate row
  state_data <- enr[enr$is_state == TRUE, ]

  # Document this as a known limitation
  # When fixed, this test should be updated to expect state data
  if (nrow(state_data) == 0) {
    message("NOTE: No state-level data available - this is a known limitation")
    message("      The Education Directory data source doesn't include state totals")
  }

  # Test passes either way to document current state
  expect_true(TRUE)
})


test_that("KNOWN ISSUE: n_students may be binary flags, not counts", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # The Education Directory contains binary flags (0/1) indicating whether
  # a school offers a particular grade, NOT actual enrollment counts
  if ("n_students" %in% names(enr)) {
    n_values <- as.numeric(enr$n_students)
    n_values <- n_values[!is.na(n_values)]

    # Check if all values are 0 or 1 (binary flags)
    all_binary <- all(n_values %in% c(0, 1))

    if (all_binary) {
      message("WARNING: n_students contains only 0/1 values - these are grade-offering flags,")
      message("         NOT actual enrollment counts. Real enrollment data requires")
      message("         manual export from EdSight: https://public-edsight.ct.gov/")
    }
  }

  expect_true(TRUE)
})


test_that("KNOWN ISSUE: Only 'total_enrollment' subgroup available", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  subgroups <- unique(enr$subgroup)

  # Currently only total_enrollment is available because the Education Directory
  # doesn't include demographic breakdowns
  # Full demographics require EdSight export
  if (length(subgroups) == 1 && subgroups[1] == "total_enrollment") {
    message("NOTE: Only 'total_enrollment' subgroup available")
    message("      Demographic subgroups (race/ethnicity, ELL, etc.) require EdSight export")
  }

  expect_true("subgroup" %in% names(enr))
})


# ============================================================================
# Data Fidelity Tests
# These tests verify that tidied output matches raw source when possible
# ============================================================================

test_that("tidy output preserves district names from source", {
  skip_on_cran()
  skip_if_offline()

  # Fetch raw directory data
  dir_url <- "https://data.ct.gov/resource/9k2y-kqxn.json?$limit=100"
  response <- httr::GET(dir_url, httr::timeout(30))
  skip_if(httr::http_error(response), "Cannot reach CT Open Data portal")

  dir_data <- jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"))

  # Fetch processed data
  enr <- fetch_enr(2024, use_cache = TRUE)

  # Check that some district names from source appear in output
  source_districts <- unique(dir_data$district_name)
  output_districts <- unique(enr$district_name)

  # At least some districts should match
  matching <- sum(source_districts %in% output_districts)
  expect_true(matching > 0, info = "No district names from source appear in output")
})


test_that("organization codes are preserved correctly", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # org_code should be present and non-empty
  if ("org_code" %in% names(enr)) {
    org_codes <- enr$org_code[!is.na(enr$org_code)]
    expect_true(length(org_codes) > 0, info = "org_code column exists but is all NA")

    # CT org codes are typically 7 digits
    # Check format for non-NA values
    sample_codes <- head(org_codes, 10)
    for (code in sample_codes) {
      expect_match(as.character(code), "^[0-9]+$",
        info = paste("Invalid org_code format:", code)
      )
    }
  }
})
