# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Connecticut State Department of Education (CSDE) via CT Open Data Portal.
#
# Data source: https://data.ct.gov/resource/9k2y-kqxn
#
# ==============================================================================

#' Fetch Connecticut school directory data
#'
#' Downloads and processes school directory data from the Connecticut Open Data
#' Portal (data.ct.gov). This includes all public educational organizations
#' in Connecticut with address and contact information.
#'
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from the API.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download.
#' @return A tibble with school directory data. Columns include:
#'   \itemize{
#'     \item \code{state_school_id}: State organization code (7 characters)
#'     \item \code{state_district_id}: District code derived from organization code
#'     \item \code{school_name}: Organization/school name
#'     \item \code{district_name}: District name
#'     \item \code{school_type}: Type of organization (e.g., "Elementary School")
#'     \item \code{grades_served}: Comma-separated list of grades offered
#'     \item \code{address}: Street address
#'     \item \code{city}: Town/city name
#'     \item \code{state}: State (always "CT")
#'     \item \code{zip}: ZIP code
#'     \item \code{phone}: Phone number
#'     \item \code{latitude}: Geographic latitude
#'     \item \code{longitude}: Geographic longitude
#'     \item \code{interdistrict_magnet}: Whether this is an interdistrict magnet
#'     \item \code{student_open_date}: Date the organization opened
#'   }
#' @details
#' The directory data is downloaded via the Socrata API from the CT Open Data
#' Portal. This data represents the official listing of all public educational
#' organizations in Connecticut as maintained by CSDE.
#'
#' Note: This data source does not include principal/superintendent names or
#' email addresses. For contact information, visit EdSight Find Contacts at
#' https://public-edsight.ct.gov/overview/find-contacts
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original API column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to elementary schools only
#' library(dplyr)
#' elementary <- dir_data |>
#'   filter(grepl("Elementary", school_type))
#'
#' # Find all schools in Hartford
#' hartford_schools <- dir_data |>
#'   filter(grepl("Hartford", district_name))
#' }
fetch_directory <- function(tidy = TRUE, use_cache = TRUE) {

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from CT Open Data
  raw <- get_raw_directory()

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from CT Open Data
#'
#' Downloads the raw school directory data from the Connecticut Open Data Portal
#' via the Socrata API.
#'
#' @return Raw data frame as downloaded from CT Open Data
#' @keywords internal
get_raw_directory <- function() {

  # Build API URL
  url <- build_directory_url()

  message("Downloading school directory data from CT Open Data Portal...")

  # Use httr for API request
  response <- httr::GET(
    url,
    httr::timeout(120),
    httr::add_headers(
      "Accept" = "application/json"
    )
  )

  # Check for successful response
  if (httr::http_error(response)) {
    stop(paste(
      "Failed to download school directory data from CT Open Data Portal.",
      "HTTP status:", httr::status_code(response)
    ))
  }

  # Parse JSON response
  content <- httr::content(response, as = "text", encoding = "UTF-8")
  df <- jsonlite::fromJSON(content, flatten = TRUE)

  # Convert to tibble
  df <- dplyr::as_tibble(df)

  message(paste("Downloaded", nrow(df), "records"))

  df
}


#' Build CT Open Data directory API URL
#'
#' Constructs the Socrata API URL for the Education Directory dataset.
#'
#' @return URL string
#' @keywords internal
build_directory_url <- function() {
  # CT Open Data Education Directory
  # Dataset ID: 9k2y-kqxn
  # Using $limit=50000 to get all records (default is 1000)
  "https://data.ct.gov/resource/9k2y-kqxn.json?$limit=50000"
}


#' Process raw school directory data to standard schema
#'
#' Takes raw school directory data from CT Open Data and standardizes column names,
#' types, and adds derived columns.
#'
#' @param raw_data Raw data frame from get_raw_directory()
#' @return Processed data frame with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  cols <- names(raw_data)

  # Build the standardized result data frame
  n_rows <- nrow(raw_data)
  result <- dplyr::tibble(.rows = n_rows)

  # Organization Code (state_school_id)
  if ("organization_code" %in% cols) {
    # Ensure consistent character format with leading zeros
    result$state_school_id <- sprintf("%07s", raw_data$organization_code)
    result$state_school_id <- gsub(" ", "0", result$state_school_id)
  }

  # Derive district ID from organization code
  # In CT, district codes are typically the first 3 digits
  if ("state_school_id" %in% names(result)) {
    result$state_district_id <- substr(result$state_school_id, 1, 3)
  }

  # School/Organization Name
  if ("name" %in% cols) {
    result$school_name <- trimws(raw_data$name)
  }

  # District Name
  if ("district_name" %in% cols) {
    result$district_name <- trimws(raw_data$district_name)
  }

  # Organization Type -> school_type
  if ("organization_type" %in% cols) {
    result$school_type <- trimws(raw_data$organization_type)
  }

  # Build grades_served from individual grade columns
  grade_cols <- c(
    "prekindergarten", "kindergarten",
    paste0("grade_", 1:12)
  )
  grade_labels <- c(
    "PK", "K",
    sprintf("%02d", 1:12)
  )

  grades_served <- character(n_rows)
  for (i in seq_len(n_rows)) {
    offered <- character(0)
    for (j in seq_along(grade_cols)) {
      if (grade_cols[j] %in% cols) {
        val <- raw_data[[grade_cols[j]]][i]
        if (!is.na(val) && val == "1") {
          offered <- c(offered, grade_labels[j])
        }
      }
    }
    grades_served[i] <- paste(offered, collapse = ",")
  }
  result$grades_served <- grades_served

  # Address fields
  if ("address" %in% cols) {
    result$address <- trimws(raw_data$address)
  }

  if ("town" %in% cols) {
    result$city <- trimws(raw_data$town)
  }

  result$state <- "CT"

  if ("zipcode" %in% cols) {
    result$zip <- trimws(raw_data$zipcode)
  }

  # Phone
  if ("phone" %in% cols) {
    result$phone <- trimws(raw_data$phone)
  }

  # These fields are not available in the CT Open Data source
  result$principal_name <- NA_character_
  result$principal_email <- NA_character_
  result$superintendent_name <- NA_character_
  result$superintendent_email <- NA_character_

  # Latitude and Longitude from geocoded_column
  if ("geocoded_column.latitude" %in% cols) {
    result$latitude <- as.numeric(raw_data[["geocoded_column.latitude"]])
  } else if ("geocoded_column" %in% cols && is.list(raw_data$geocoded_column)) {
    # Try to extract from nested structure
    result$latitude <- sapply(raw_data$geocoded_column, function(x) {
      if (is.null(x) || !is.list(x)) return(NA_real_)
      if ("latitude" %in% names(x)) as.numeric(x$latitude) else NA_real_
    })
  }

  if ("geocoded_column.longitude" %in% cols) {
    result$longitude <- as.numeric(raw_data[["geocoded_column.longitude"]])
  } else if ("geocoded_column" %in% cols && is.list(raw_data$geocoded_column)) {
    result$longitude <- sapply(raw_data$geocoded_column, function(x) {
      if (is.null(x) || !is.list(x)) return(NA_real_)
      if ("longitude" %in% names(x)) as.numeric(x$longitude) else NA_real_
    })
  }

  # Interdistrict magnet status
  if ("interdistrict_magnet" %in% cols) {
    result$interdistrict_magnet <- raw_data$interdistrict_magnet == "1"
  }

  # Student open date
  if ("student_open_date" %in% cols) {
    result$student_open_date <- raw_data$student_open_date
  }

  # Reorder columns for consistency with standard schema
  preferred_order <- c(
    "state_school_id", "state_district_id",
    "school_name", "district_name", "school_type",
    "grades_served",
    "address", "city", "state", "zip", "phone",
    "principal_name", "principal_email",
    "superintendent_name", "superintendent_email",
    "latitude", "longitude",
    "interdistrict_magnet", "student_open_date"
  )

  existing_cols <- preferred_order[preferred_order %in% names(result)]
  other_cols <- setdiff(names(result), preferred_order)

  result <- result |>
    dplyr::select(dplyr::all_of(c(existing_cols, other_cols)))

  result
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @param max_age Maximum age in days (default 30). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 30) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
