# Tests for fetch functions

test_that("fetch_enr validates year input", {
  # Invalid year should error
  expect_error(fetch_enr(1990), "end_year must be between")
  expect_error(fetch_enr(2050), "end_year must be between")
})


test_that("fetch_enr_multi validates years", {
  # Invalid years should error
  expect_error(fetch_enr_multi(c(1990, 2020)), "Invalid years")
})


test_that("import_local_enr validates file path", {
  # Non-existent file should error
  expect_error(import_local_enr("nonexistent.xlsx", 2024), "File not found")

  # Invalid file type should error
  tmp_file <- tempfile(fileext = ".txt")
  writeLines("test", tmp_file)
  expect_error(import_local_enr(tmp_file, 2024), "Unsupported file type")
  unlink(tmp_file)
})
