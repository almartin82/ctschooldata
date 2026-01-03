# ==============================================================================
# Data Fidelity Tests
# ==============================================================================
#
# These tests verify that the tidied/processed output maintains fidelity
# to the raw source data from CTData.org and CT Open Data.
#
# Data Source Coverage:
# - CTData.org: 2007-2016 (actual enrollment counts, ~6 sample districts)
# - CT Open Data Education Directory: 2017+ (binary grade flags only)
#
# ==============================================================================

# ==============================================================================
# CTData.org Fidelity Tests (Years 2007-2016)
# These years have actual enrollment counts from CTData.org
# ==============================================================================

test_that("CTData years (2008-2016) have actual enrollment counts, not binary flags", {
  skip_on_cran()
  skip_if_offline()

  # These years should have real enrollment data from CTData.org
  ctdata_years <- c(2008, 2010, 2012, 2015)

  for (yr in ctdata_years) {
    enr <- tryCatch(
      fetch_enr(yr, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(enr) && nrow(enr) > 0) {
      n_vals <- enr$n_students[!is.na(enr$n_students)]

      # Should have values > 1 (not just binary flags)
      max_val <- max(n_vals)
      expect_true(max_val > 1,
        info = paste("Year", yr, "should have enrollment counts > 1, got max:", max_val)
      )
    }
  }
})


test_that("CTData years have consistent grade level coverage", {
  skip_on_cran()
  skip_if_offline()

  # Expected standard grades
  expected_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                       "07", "08", "09", "10", "11", "12", "TOTAL")

  enr_2015 <- tryCatch(
    fetch_enr(2015, use_cache = TRUE),
    error = function(e) NULL
  )

  if (!is.null(enr_2015) && nrow(enr_2015) > 0) {
    actual_grades <- sort(unique(enr_2015$grade_level))

    # Should have most standard grades
    coverage <- sum(expected_grades %in% actual_grades) / length(expected_grades)
    expect_true(coverage > 0.8,
      info = paste("Expected 80%+ grade coverage, got:", round(coverage * 100), "%")
    )
  }
})


test_that("CTData district names are preserved accurately", {
  skip_on_cran()
  skip_if_offline()

  # Fetch raw data directly from CTData.org
  csv_url <- "http://data.ctdata.org/dataset/dc58f70e-fdd1-4a9b-8481-30fe10c62c24/resource/5110f7f5-55da-4803-9a63-1e21e8077251/download/student-enrollment-by-grade2007-2016.csv"

  raw_data <- tryCatch(
    readr::read_csv(csv_url, show_col_types = FALSE),
    error = function(e) NULL
  )

  skip_if(is.null(raw_data), "Cannot fetch CTData.org enrollment CSV")

  # Get 2015 data
  raw_2015 <- raw_data[grepl("2014-2015", raw_data$Year), ]

  if (nrow(raw_2015) > 0) {
    # Fetch processed data
    processed_2015 <- tryCatch(
      fetch_enr(2015, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(processed_2015) && nrow(processed_2015) > 0) {
      raw_districts <- unique(raw_2015$District)
      processed_districts <- unique(processed_2015$district_name)

      # Check that raw district names appear in processed output
      matching <- sum(raw_districts %in% processed_districts)
      expect_true(matching > 0,
        info = "District names from raw CTData should appear in processed output"
      )
    }
  }
})


test_that("CTData enrollment values match raw source", {
  skip_on_cran()
  skip_if_offline()

  # Fetch raw data directly from CTData.org
  csv_url <- "http://data.ctdata.org/dataset/dc58f70e-fdd1-4a9b-8481-30fe10c62c24/resource/5110f7f5-55da-4803-9a63-1e21e8077251/download/student-enrollment-by-grade2007-2016.csv"

  raw_data <- tryCatch(
    readr::read_csv(csv_url, show_col_types = FALSE),
    error = function(e) NULL
  )

  skip_if(is.null(raw_data), "Cannot fetch CTData.org enrollment CSV")

  # Get 2015 data
  raw_2015 <- raw_data[grepl("2014-2015", raw_data$Year), ]

  # Find a specific district/grade combination
  if (nrow(raw_2015) > 0) {
    # Get first district's total
    test_district <- raw_2015$District[1]
    raw_total <- raw_2015[raw_2015$District == test_district & raw_2015$Grade == "Total", ]

    if (nrow(raw_total) > 0) {
      raw_value <- raw_total$Value[1]

      # Skip if suppressed
      if (!is.na(raw_value) && raw_value >= 0) {
        # Fetch processed data
        processed_2015 <- tryCatch(
          fetch_enr(2015, use_cache = TRUE),
          error = function(e) NULL
        )

        if (!is.null(processed_2015) && nrow(processed_2015) > 0) {
          processed_total <- processed_2015[
            processed_2015$district_name == test_district &
            processed_2015$grade_level == "TOTAL" &
            processed_2015$subgroup == "total_enrollment",
          ]

          if (nrow(processed_total) > 0) {
            processed_value <- processed_total$n_students[1]

            # Values should match
            expect_equal(processed_value, raw_value,
              info = paste("Enrollment for", test_district, "should match raw data")
            )
          }
        }
      }
    }
  }
})


# ==============================================================================
# Suppression Marker Tests
# Verify that suppression markers (-9999, -6666) are handled correctly
# ==============================================================================

test_that("negative suppression markers are converted to NA", {
  skip_on_cran()
  skip_if_offline()

  # Years that historically had suppression markers
  test_years <- c(2008, 2012, 2015)

  for (yr in test_years) {
    enr <- tryCatch(
      fetch_enr(yr, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(enr) && nrow(enr) > 0 && "n_students" %in% names(enr)) {
      n_vals <- enr$n_students[!is.na(enr$n_students)]

      # Should have no negative values (suppression markers should be NA)
      neg_count <- sum(n_vals < 0)
      expect_equal(neg_count, 0,
        info = paste("Year", yr, "has", neg_count, "negative n_students values - should be NA")
      )
    }
  }
})


test_that("safe_numeric correctly handles CTData suppression markers", {
  # Test the safe_numeric function directly

  # Numeric suppression markers
  expect_true(is.na(safe_numeric("-9999")))
  expect_true(is.na(safe_numeric("-6666")))
  expect_true(is.na(safe_numeric("-1")))

  # Text suppression markers
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("***")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("N/A")))

  # Valid values should pass through
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)
  expect_equal(safe_numeric(" 50 "), 50)
  expect_equal(safe_numeric("0"), 0)
})


# ==============================================================================
# Education Directory Fidelity Tests (Years 2017+)
# These years use CT Open Data Education Directory (binary grade flags)
# ==============================================================================

test_that("Education Directory years correctly identify organization types", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Should have type column
  expect_true("type" %in% names(enr))

  types <- unique(enr$type)

  # Should have District and Campus types
  expect_true("District" %in% types,
    info = "Should identify district-level organizations"
  )
  expect_true("Campus" %in% types,
    info = "Should identify campus-level organizations"
  )
})


test_that("Education Directory preserves org_codes", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  if ("org_code" %in% names(enr)) {
    org_codes <- enr$org_code[!is.na(enr$org_code)]

    # Should have org_codes
    expect_true(length(org_codes) > 0,
      info = "Should have organization codes from Education Directory"
    )

    # CT org codes are numeric
    sample_codes <- head(org_codes, 10)
    for (code in sample_codes) {
      expect_match(as.character(code), "^[0-9]+$",
        info = paste("Invalid org_code format:", code)
      )
    }
  }
})


test_that("Education Directory data has expected district count", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Filter to districts only
  districts <- unique(enr$district_name[enr$is_district])

  # CT has ~200+ school districts
  expect_true(length(districts) > 150,
    info = paste("Expected 150+ districts, got:", length(districts))
  )
})


# ==============================================================================
# Year-by-Year Coverage Tests
# Verify each year has data and expected structure
# ==============================================================================

test_that("all years 2007-2024 return valid data", {
  skip_on_cran()
  skip_if_offline()

  years <- get_available_years(check_api = FALSE)

  # Test each year
  for (yr in years) {
    enr <- tryCatch(
      fetch_enr(yr, use_cache = TRUE),
      error = function(e) NULL
    )

    # Should return non-null data frame
    expect_true(!is.null(enr),
      info = paste("Year", yr, "should return data")
    )

    if (!is.null(enr)) {
      expect_s3_class(enr, "data.frame")

      expect_true(nrow(enr) > 0,
        info = paste("Year", yr, "should have rows")
      )

      # Required columns
      required <- c("end_year", "type", "district_name", "grade_level",
                    "subgroup", "n_students")
      for (col in required) {
        expect_true(col %in% names(enr),
          info = paste("Year", yr, "missing column:", col)
        )
      }
    }
  }
})


test_that("end_year column is correct for each fetched year", {
  skip_on_cran()
  skip_if_offline()

  test_years <- c(2008, 2015, 2020, 2024)

  for (yr in test_years) {
    enr <- tryCatch(
      fetch_enr(yr, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(enr) && nrow(enr) > 0) {
      # All rows should have the correct end_year
      expect_true(all(enr$end_year == yr),
        info = paste("Year", yr, "should have end_year ==", yr)
      )
    }
  }
})


# ==============================================================================
# Grade Level Standardization Tests
# ==============================================================================

test_that("grade levels are standardized correctly", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2015, use_cache = TRUE)

  if (!is.null(enr) && nrow(enr) > 0) {
    grades <- unique(enr$grade_level)

    # Check standardized format
    valid_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                      "07", "08", "09", "10", "11", "12", "TOTAL")

    for (g in grades) {
      expect_true(g %in% valid_grades,
        info = paste("Unexpected grade level:", g)
      )
    }

    # Two-digit grades (01-09) should be zero-padded
    if ("1" %in% grades) {
      fail("Grade '1' should be standardized to '01'")
    }
    if ("9" %in% grades) {
      fail("Grade '9' should be standardized to '09'")
    }
  }
})


# ==============================================================================
# Subgroup Coverage Tests
# ==============================================================================

test_that("at least total_enrollment subgroup is present", {
  skip_on_cran()
  skip_if_offline()

  test_years <- c(2010, 2015, 2020, 2024)

  for (yr in test_years) {
    enr <- tryCatch(
      fetch_enr(yr, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(enr) && nrow(enr) > 0) {
      subgroups <- unique(enr$subgroup)

      expect_true("total_enrollment" %in% subgroups,
        info = paste("Year", yr, "should have 'total_enrollment' subgroup")
      )
    }
  }
})


# ==============================================================================
# Aggregation Flag Tests
# ==============================================================================

test_that("aggregation flags are correctly set", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Check that flags exist
  expect_true("is_state" %in% names(enr))
  expect_true("is_district" %in% names(enr))
  expect_true("is_campus" %in% names(enr))
  expect_true("is_charter" %in% names(enr))

  # Flags should be logical
  expect_type(enr$is_state, "logical")
  expect_type(enr$is_district, "logical")
  expect_type(enr$is_campus, "logical")
  expect_type(enr$is_charter, "logical")

  # District and campus flags should be mutually exclusive per row
  overlap <- sum(enr$is_district & enr$is_campus, na.rm = TRUE)
  expect_equal(overlap, 0,
    info = "is_district and is_campus should be mutually exclusive"
  )
})


# ==============================================================================
# Multi-Year Consistency Tests
# ==============================================================================

test_that("multi-year fetch returns all requested years", {
  skip_on_cran()
  skip_if_offline()

  # Test with CTData years that should all have data
  test_years <- c(2008, 2010, 2012)

  enr <- tryCatch(
    fetch_enr_multi(test_years, use_cache = TRUE),
    error = function(e) NULL
  )

  if (!is.null(enr) && nrow(enr) > 0) {
    years_returned <- sort(unique(enr$end_year))

    # Should have all requested years
    for (yr in test_years) {
      expect_true(yr %in% years_returned,
        info = paste("Multi-year fetch should include year", yr)
      )
    }
  }
})


test_that("column schema is consistent across years", {
  skip_on_cran()
  skip_if_offline()

  # Test years from different data sources
  test_years <- c(2010, 2015, 2020, 2024)

  required_cols <- c("end_year", "type", "district_name",
                     "grade_level", "subgroup", "n_students")

  for (yr in test_years) {
    enr <- tryCatch(
      fetch_enr(yr, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(enr) && nrow(enr) > 0) {
      for (col in required_cols) {
        expect_true(col %in% names(enr),
          info = paste("Year", yr, "missing required column:", col)
        )
      }
    }
  }
})
