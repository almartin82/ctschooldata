# Tests for utility functions

test_that("get_available_years returns valid range", {
  years <- get_available_years(check_api = FALSE)

  # Should return integer vector
  expect_type(years, "integer")

  # Should include historical years
  expect_true(2007 %in% years)
  expect_true(2010 %in% years)
  expect_true(2015 %in% years)
  expect_true(2020 %in% years)

  # Should be sequential
  expect_equal(years, min(years):max(years))

  # Should start from 2007 (first EdSight year)
  expect_equal(min(years), 2007)

  # Should extend to at least 2024 (last confirmed year with data)
  # NOTE: EdSight data must be manually exported; max year is set in get_available_years()
  expect_true(max(years) >= 2024)
})


test_that("safe_numeric handles suppression markers", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,000"), 1000)
  expect_equal(safe_numeric(" 50 "), 50)

  # Suppression markers should become NA
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("***")))
  expect_true(is.na(safe_numeric("N/A")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("-")))
  expect_true(is.na(safe_numeric("")))
})


test_that("format_school_year formats correctly", {
  expect_equal(format_school_year(2024), "2023-24")
  expect_equal(format_school_year(2020), "2019-20")
  expect_equal(format_school_year(2007), "2006-07")
})


test_that("parse_school_year parses correctly", {
  expect_equal(parse_school_year("2023-24"), 2024)
  expect_equal(parse_school_year("2023-2024"), 2024)
  expect_equal(parse_school_year("2023/24"), 2024)
  expect_equal(parse_school_year("2006-07"), 2007)
})
