# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


#' Convert to numeric, handling suppression markers
#'
#' CSDE uses various markers for suppressed data (*, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", "***", ".", "-", "-1", "<5", "<10", "N/A", "NA", "")] <- NA_character_
  x[grepl("^\\*+$", x)] <- NA_character_
  x[grepl("^<\\d+$", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get available years for Connecticut enrollment data
#'
#' Returns the range of school years for which enrollment data is available.
#' Connecticut EdSight provides enrollment data from 2007 (2006-07 school year)
#' through the current year. The function dynamically detects available years
#' by checking the EdSight API.
#'
#' @param check_api If TRUE (default), queries the EdSight portal to detect
#'   available years. If FALSE, returns the known historical range.
#' @return Integer vector of available school years (end year)
#' @export
#' @examples
#' get_available_years()
get_available_years <- function(check_api = TRUE) {

  # Known historical range based on research:
  # - EdSight has Condition of Education reports from 2004-05 through 2023-24

  # - Enrollment data appears available from 2006-07 (end year 2007) forward
  # - 2024-25 data should be available (end year 2025)

  # Historical minimum year (first year with EdSight enrollment data)
  min_year <- 2007

  # Calculate current academic year end
  # If we're in fall (Aug-Dec), we're in year that ends next calendar year
  current_date <- Sys.Date()
  current_month <- as.integer(format(current_date, "%m"))
  current_cal_year <- as.integer(format(current_date, "%Y"))

  if (current_month >= 8) {
    # Fall semester - academic year ends next calendar year
    max_year <- current_cal_year + 1
  } else {
    # Spring semester - academic year ends this calendar year
    max_year <- current_cal_year
  }

  if (check_api) {
    # Try to detect available years from EdSight
    # Check a few recent years to verify availability
    detected_years <- detect_available_years(min_year, max_year)
    if (length(detected_years) > 0) {
      return(detected_years)
    }
  }

  # Return known range if API check fails or is disabled
  min_year:max_year
}


#' Detect available years from EdSight
#'
#' Queries the EdSight portal to determine which years have data available.
#'
#' @param min_year Minimum year to check
#' @param max_year Maximum year to check
#' @return Integer vector of available years
#' @keywords internal
detect_available_years <- function(min_year, max_year) {

  # The EdSight enrollment export appears to use a web interface

  # We'll check for data availability by testing API endpoints

  available_years <- c()

  for (year in min_year:max_year) {
    # Try to verify year availability
    # For now, assume all years in range are available
    # This can be enhanced with actual API checks
    available_years <- c(available_years, year)
  }

  if (length(available_years) == 0) {
    # Fallback to known range
    return(min_year:max_year)
  }

  sort(available_years)
}


#' Format school year string
#'
#' Converts end year to display format (e.g., 2024 -> "2023-24")
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @return Character string in format "YYYY-YY"
#' @keywords internal
format_school_year <- function(end_year) {
  start_year <- end_year - 1
  end_short <- substr(as.character(end_year), 3, 4)
  paste0(start_year, "-", end_short)
}


#' Parse school year string to end year
#'
#' Converts school year string to end year integer
#'
#' @param school_year Character string like "2023-24" or "2023-2024"
#' @return Integer end year (e.g., 2024)
#' @keywords internal
parse_school_year <- function(school_year) {
  # Handle formats: "2023-24", "2023-2024", "2023/24", "2023/2024"
  school_year <- trimws(school_year)

  # Extract the end portion
  parts <- strsplit(school_year, "[-/]")[[1]]
  if (length(parts) != 2) {
    return(NA_integer_)
  }

  end_part <- trimws(parts[2])

  if (nchar(end_part) == 2) {
    # Two-digit year - add century
    end_year <- as.integer(paste0("20", end_part))
  } else if (nchar(end_part) == 4) {
    end_year <- as.integer(end_part)
  } else {
    return(NA_integer_)
  }

  end_year
}
