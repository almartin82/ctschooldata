# Tests for cache functions

test_that("get_cache_dir creates directory", {
  cache_dir <- get_cache_dir()

  # Should return a path
  expect_type(cache_dir, "character")

  # Directory should exist
  expect_true(dir.exists(cache_dir))

  # Should be in user cache directory
  expect_true(grepl("ctschooldata", cache_dir))
})


test_that("get_cache_path generates correct paths", {
  path <- get_cache_path(2024, "tidy")

  expect_true(grepl("enr_tidy_2024\\.rds$", path))

  path_wide <- get_cache_path(2020, "wide")
  expect_true(grepl("enr_wide_2020\\.rds$", path_wide))
})


test_that("cache_exists returns FALSE for non-existent cache", {
  # Unlikely to have cached data for year 2099
  expect_false(cache_exists(2099, "tidy"))
})
