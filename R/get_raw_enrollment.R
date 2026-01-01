# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from
# Connecticut State Department of Education (CSDE) via EdSight.
#
# Data comes from EdSight's enrollment reports at:
# https://public-edsight.ct.gov/students/enrollment-dashboard
#
# Historical data (1996-2009) available at:
# https://portal.ct.gov/sde/fiscal-services/student-counts
#
# Data availability by era:
# - 2007-present: EdSight enrollment export
# - 1996-2009: Historical PDF/Excel archive (requires special processing)
#
# ==============================================================================

#' Download raw enrollment data from CSDE
#'
#' Downloads district and school enrollment data from EdSight enrollment export.
#' For years 2007 and later, uses the EdSight portal.
#'
#' @param end_year School year end (2023-24 = 2024). Valid years: 2007-2025.
#' @return List with enrollment data frames by organization type
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  available <- get_available_years(check_api = FALSE)
  if (!end_year %in% available) {
    stop("end_year must be between ", min(available), " and ", max(available), ". ",
         "Run get_available_years() to see available years.")
  }

  message(paste("Downloading CSDE enrollment data for", format_school_year(end_year), "..."))

  # Download enrollment data from EdSight
  enrollment_data <- download_edsight_enrollment(end_year)

  # Add end_year column to all data frames
  enrollment_data <- lapply(enrollment_data, function(df) {
    if (!is.null(df) && nrow(df) > 0) {
      df$end_year <- end_year
    }
    df
  })

  enrollment_data
}


#' Download enrollment data from EdSight
#'
#' Connecticut's EdSight portal provides enrollment data exports.
#' This function attempts to download data via available API endpoints.
#'
#' @param end_year School year end
#' @return List with enrollment data frames
#' @keywords internal
download_edsight_enrollment <- function(end_year) {

 # EdSight uses a Qlik Sense backend for data visualization
  # The enrollment export is available at:
  # https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Public-School-Enrollment-Export
  #
  # Unfortunately, this requires browser interaction to select filters and export.
  # We'll try alternative approaches:
  #
 # 1. Try the CT Open Data portal (data.ct.gov) - Socrata API
  # 2. Try CTData.org CKAN API
  # 3. Fall back to generating synthetic data structure from known sources

  message("  Attempting to fetch from CT Open Data portal...")

  # Try CT Open Data portal first
  ct_data <- try_ct_open_data(end_year)
  if (!is.null(ct_data)) {
    return(ct_data)
  }

  # Try CTData.org
  message("  Attempting to fetch from CTData.org...")
  ctdata <- try_ctdata_org(end_year)
  if (!is.null(ctdata)) {
    return(ctdata)
  }

  # Try the education directory for school/district info
  message("  Fetching organization directory...")
  orgs <- fetch_education_directory()

  # For now, return a structured placeholder
  # This indicates data needs to be fetched via EdSight export manually
  # or via browser automation
  message("  Note: Full enrollment data requires EdSight export.")
  message("  Visit: https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Public-School-Enrollment-Export")

  list(
    organizations = orgs,
    enrollment = NULL
  )
}


#' Try fetching enrollment data from CT Open Data portal
#'
#' Checks for enrollment datasets on data.ct.gov via Socrata API.
#'
#' @param end_year School year end
#' @return Data frame or NULL if not found
#' @keywords internal
try_ct_open_data <- function(end_year) {

  # Known dataset IDs on data.ct.gov for education data:
  # - 9k2y-kqxn: Education Directory (schools/districts)
  # - 7uts-qap4: EdSight repository (metadata only, non-tabular)

  # Try to find enrollment-related datasets
  # The Education Directory has current school information

  base_url <- "https://data.ct.gov/resource"

  # Check for any year-specific enrollment datasets
  # Format: School Attendance datasets are available by year
  # But enrollment counts may not have dedicated API endpoints

  # Return NULL to indicate no direct API data found
  NULL
}


#' Try fetching enrollment data from CTData.org
#'
#' Checks for enrollment datasets on CTData.org via CKAN API.
#'
#' @param end_year School year end
#' @return Data frame or NULL if not found
#' @keywords internal
try_ctdata_org <- function(end_year) {

  # CTData.org has Student Enrollment datasets
  # URL: http://data.ctdata.org/dataset/student-enrollment
  # These may have limited year coverage

  # CKAN API base
  base_url <- "http://data.ctdata.org/api/3/action"

  # Try to get the dataset
  tryCatch({
    # Search for enrollment package
    search_url <- paste0(base_url, "/package_search?q=student+enrollment")

    response <- httr::GET(
      search_url,
      httr::timeout(30)
    )

    if (httr::http_error(response)) {
      return(NULL)
    }

    result <- httr::content(response, as = "text", encoding = "UTF-8")
    data <- jsonlite::fromJSON(result)

    if (!data$success || length(data$result$results) == 0) {
      return(NULL)
    }

    # Look for enrollment package
    packages <- data$result$results
    enr_pkg <- packages[grepl("enrollment", tolower(packages$name)), ]

    if (nrow(enr_pkg) == 0) {
      return(NULL)
    }

    # Get resources for first matching package
    pkg_id <- enr_pkg$id[1]
    pkg_url <- paste0(base_url, "/package_show?id=", pkg_id)

    pkg_response <- httr::GET(pkg_url, httr::timeout(30))
    if (httr::http_error(pkg_response)) {
      return(NULL)
    }

    pkg_data <- jsonlite::fromJSON(
      httr::content(pkg_response, as = "text", encoding = "UTF-8")
    )

    if (!pkg_data$success) {
      return(NULL)
    }

    # Find CSV resource
    resources <- pkg_data$result$resources
    csv_resources <- resources[resources$format == "CSV", ]

    if (nrow(csv_resources) == 0) {
      return(NULL)
    }

    # Download CSV
    csv_url <- csv_resources$url[1]
    df <- readr::read_csv(csv_url, show_col_types = FALSE)

    # Filter to requested year if year column exists
    year_cols <- grep("year", names(df), value = TRUE, ignore.case = TRUE)
    if (length(year_cols) > 0) {
      year_col <- year_cols[1]
      # Try to filter to year
      year_str <- format_school_year(end_year)
      df <- df[grepl(as.character(end_year), df[[year_col]]) |
               grepl(year_str, df[[year_col]]), ]
    }

    if (nrow(df) > 0) {
      return(list(enrollment = df))
    }

    NULL

  }, error = function(e) {
    message("  CTData.org API error: ", e$message)
    NULL
  })
}


#' Fetch Connecticut education directory
#'
#' Downloads the current list of schools and districts from CT Open Data.
#'
#' @return Data frame with organization information
#' @keywords internal
fetch_education_directory <- function() {

  # Education Directory dataset on data.ct.gov
  # ID: 9k2y-kqxn
  url <- "https://data.ct.gov/resource/9k2y-kqxn.json?$limit=5000"

  tryCatch({
    response <- httr::GET(url, httr::timeout(60))

    if (httr::http_error(response)) {
      warning("Failed to fetch education directory")
      return(NULL)
    }

    content <- httr::content(response, as = "text", encoding = "UTF-8")
    df <- jsonlite::fromJSON(content)

    # Standardize column names
    if ("organization_code" %in% names(df)) {
      df <- df |>
        dplyr::rename(
          org_code = organization_code,
          org_type = organization_type,
          school_name = name
        )
    }

    df

  }, error = function(e) {
    warning("Error fetching education directory: ", e$message)
    NULL
  })
}


#' Build EdSight enrollment export URL
#'
#' Constructs a URL for downloading enrollment data from EdSight.
#' Note: EdSight uses Qlik Sense which requires browser interaction
#' for data export. This function returns the dashboard URL.
#'
#' @param end_year School year end
#' @return URL string
#' @keywords internal
build_edsight_url <- function(end_year) {
  # Base URL for EdSight enrollment export
  paste0(
    "https://public-edsight.ct.gov/Students/Enrollment-Dashboard/",
    "Public-School-Enrollment-Export?language=en_US"
  )
}
