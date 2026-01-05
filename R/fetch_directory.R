# ==============================================================================
# Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Connecticut Open Data Portal (data.ct.gov) Socrata API.
#
# Dataset: Education Directory
# Dataset ID: 9k2y-kqxn
# Source URL: https://data.ct.gov/Education/Education-Directory/9k2y-kqxn
#
# ==============================================================================

#' Fetch Connecticut school directory data
#'
#' Downloads and processes school directory data from the Connecticut Open Data
#' Portal (data.ct.gov). The Education Directory contains information about
#' public schools, districts, and endowed academies including names, addresses,
#' phone numbers, grade levels served, and organization codes.
#'
#' @param tidy If TRUE (default), returns data with standardized column names.
#'   If FALSE, returns raw API response format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from API.
#' @return Data frame with directory information. If tidy=TRUE, includes columns:
#'   \describe{
#'     \item{end_year}{Always NA (directory data is current, not year-specific)}
#'     \item{state_school_id}{7-digit CT organization code}
#'     \item{state_district_id}{3-digit CT district code}
#'     \item{nces_school_id}{Always NA (not in source)}
#'     \item{nces_district_id}{Always NA (not in source)}
#'     \item{school_name}{School or organization name}
#'     \item{district_name}{District name}
#'     \item{school_type}{Organization type (e.g., "Public Schools", "Public School Districts")}
#'     \item{grades_served}{Grade span (e.g., "K-5", "9-12")}
#'     \item{address}{Street address}
#'     \item{city}{City/town}
#'     \item{state}{Always "CT"}
#'     \item{zip}{ZIP code}
#'     \item{phone}{Phone number}
#'     \item{latitude}{Geographic latitude (if available)}
#'     \item{longitude}{Geographic longitude (if available)}
#'     \item{principal_name}{Always NA (not in source)}
#'     \item{principal_email}{Always NA (not in source)}
#'     \item{superintendent_name}{Always NA (not in source)}
#'     \item{superintendent_email}{Always NA (not in source)}
#'   }
#' @note The CT Open Data Education Directory does not include administrator
#'   contact information (names, emails). These fields are included in the
#'   output for schema compatibility but are set to NA.
#' @export
#' @examples
#' \dontrun{
#' # Get current directory data
#' directory <- fetch_directory()
#'
#' # Get raw format
#' directory_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download
#' directory_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Find all high schools
#' high_schools <- directory |>
#'   dplyr::filter(grepl("High School", school_name))
#' }
fetch_directory <- function(tidy = TRUE, use_cache = TRUE) {

  # Check cache first
  if (use_cache && directory_cache_exists()) {
    message("Using cached directory data")
    cached <- read_directory_cache()

    if (tidy) {
      return(process_directory(cached))
    } else {
      return(cached)
    }
  }

  # Get raw data from API
  raw <- get_raw_directory()

  # Cache raw data
  if (use_cache) {
    write_directory_cache(raw)
  }

  # Process if requested
  if (tidy) {
    processed <- process_directory(raw)
  } else {
    processed <- raw
  }

  processed
}


#' Get raw directory data from CT Open Data API
#'
#' Downloads the complete Education Directory dataset from data.ct.gov.
#'
#' @return Raw data frame from API response
#' @keywords internal
get_raw_directory <- function() {

  # CT Open Data Education Directory API endpoint
  url <- "https://data.ct.gov/resource/9k2y-kqxn.json"

  message("Downloading directory data from CT Open Data...")

  # Request all records (Socrata API limit is 50,000 by default)
  response <- httr::GET(
    url,
    query = list(
      `$limit` = 50000  # Get all records
    ),
    httr::timeout(60)
  )

  # Check for errors
  if (httr::http_error(response)) {
    status <- httr::status_code(response)
    stop(paste("Failed to download directory data. HTTP", status))
  }

  # Parse JSON
  content <- httr::content(response, as = "text", encoding = "UTF-8")
  raw_df <- jsonlite::fromJSON(content, flatten = TRUE)

  message(paste("Downloaded", nrow(raw_df), "records"))

  raw_df
}


#' Process directory data to standard schema
#'
#' Transforms raw API response into standardized format with consistent
#' column names and data types.
#'
#' @param raw_df Raw data frame from get_raw_directory()
#' @return Processed tibble with standardized schema
#' @keywords internal
process_directory <- function(raw_df) {

  # Ensure raw_df is a data frame
  if (!is.data.frame(raw_df)) {
    stop("raw_df must be a data frame")
  }

  # Extract latitude/longitude from geocoded_column if present
  if ("geocoded_column.latitude" %in% names(raw_df)) {
    raw_df$latitude <- as.numeric(raw_df$`geocoded_column.latitude`)
  }
  if ("geocoded_column.longitude" %in% names(raw_df)) {
    raw_df$longitude <- as.numeric(raw_df$`geocoded_column.longitude`)
  }

  # Parse organization codes
  # CT organization codes are 7 digits:
  # - Districts: XXX0011 (where XXX is district code)
  # - Schools: XXYYZ11 (where XXX is district code)
  processed <- raw_df |>
    dplyr::mutate(
      # Keep organization_code as character to preserve leading zeros
      organization_code = as.character(organization_code),

      # Extract district code (first 3 digits)
      state_district_id = substr(organization_code, 1, 3),

      # Build grades_served from grade flags using row-wise application
      grades_served = purrr::pmap_chr(
        list(prekindergarten, kindergarten, grade_1, grade_2, grade_3,
             grade_4, grade_5, grade_6, grade_7, grade_8, grade_9,
             grade_10, grade_11, grade_12),
        build_grade_span
      )
    ) |>
    dplyr::select(
      state_school_id = organization_code,
      state_district_id,
      school_name = name,
      district_name,
      school_type = organization_type,
      grades_served,
      address,
      city = town,
      zip = zipcode,
      phone,
      latitude,
      longitude
    )

  # Add NA columns that are required by schema but not in source
  processed$end_year <- NA_integer_
  processed$nces_school_id <- NA_character_
  processed$nces_district_id <- NA_character_
  processed$state <- "CT"
  processed$principal_name <- NA_character_
  processed$principal_email <- NA_character_
  processed$superintendent_name <- NA_character_
  processed$superintendent_email <- NA_character_

  # Convert to tibble
  processed <- dplyr::tibble(processed)

  processed
}


#' Build grade span string from grade flags
#'
#' Constructs a grade span representation (e.g., "K-5", "6-8", "9-12")
#' from binary grade offering flags.
#'
#' @param ... Grade flag columns (prekindergarten through grade_12)
#' @return Character vector of grade spans
#' @keywords internal
build_grade_span <- function(...) {

  grade_flags <- list(...)

  # Map column positions to grade labels
  grade_labels <- c(
    "PK", "K", "01", "02", "03", "04", "05", "06",
    "07", "08", "09", "10", "11", "12"
  )

  # Convert flags to logical (treat "1", 1, TRUE as offered)
  grade_offered <- sapply(grade_flags, function(flag) {
    isTRUE(as.logical(as.numeric(flag)))
  })

  # Build grade span
  offered_grades <- grade_labels[grade_offered]

  if (length(offered_grades) == 0) {
    return(NA_character_)
  }

  # Find continuous ranges
  ranges <- list()
  start_idx <- 1

  for (i in seq_along(offered_grades)) {
    if (i == length(offered_grades) ||
        which(grade_labels == offered_grades[i + 1]) -
        which(grade_labels == offered_grades[i]) != 1) {
      # End of continuous range
      ranges[[length(ranges) + 1]] <- offered_grades[start_idx:i]
      start_idx <- i + 1
    }
  }

  # Format ranges
  span_parts <- sapply(ranges, function(range) {
    if (length(range) == 1) {
      return(range)
    } else {
      return(paste(range[1], range[length(range)], sep = "-"))
    }
  })

  paste(span_parts, collapse = ", ")
}


#' Check if directory cache exists and is valid
#'
#' @param max_age Maximum age in days (default 30)
#' @return TRUE if valid cache exists
#' @keywords internal
directory_cache_exists <- function(max_age = 30) {

  cache_path <- get_directory_cache_path()

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Get directory cache file path
#'
#' @return Full path to directory cache file
#' @keywords internal
get_directory_cache_path <- function() {

  cache_dir <- file.path(
    rappdirs::user_cache_dir("ctschooldata"),
    "data"
  )

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  file.path(cache_dir, "directory.rds")
}


#' Read directory data from cache
#'
#' @return Cached data frame
#' @keywords internal
read_directory_cache <- function() {

  cache_path <- get_directory_cache_path()
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param df Data frame to cache
#' @return Invisibly returns the cache path
#' @keywords internal
write_directory_cache <- function(df) {

  cache_path <- get_directory_cache_path()
  saveRDS(df, cache_path)
  invisible(cache_path)
}


#' Clear the directory cache
#'
#' Removes the cached directory data file.
#'
#' @return Invisibly returns TRUE if cache was deleted, FALSE if it didn't exist
#' @export
#' @examples
#' \dontrun{
#' # Clear directory cache
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {

  cache_path <- get_directory_cache_path()

  if (file.exists(cache_path)) {
    file.remove(cache_path)
    message("Directory cache cleared")
    invisible(TRUE)
  } else {
    message("No directory cache found")
    invisible(FALSE)
  }
}
