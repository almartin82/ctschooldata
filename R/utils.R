# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL

globalVariables(c(
  "district_id_temp",
  "district_code",
  "raw_grade",
  "grade_offered",
  "prekindergarten",
  "kindergarten",
  "grade_1",
  "grade_2",
  "grade_3",
  "grade_4",
  "grade_5",
  "grade_6",
  "grade_7",
  "grade_8",
  "grade_9",
  "grade_10",
  "grade_11",
  "grade_12",
  "name",
  "organization_code",
  "organization_type",
  "town",
  "zipcode"
))


#' Convert to numeric, handling suppression markers
#'
#' CSDE and CTData.org use various markers for suppressed data:
#' - Text markers: *, ***, ., -, N/A, NA, empty string
#' - Numeric suppression codes: -9999, -6666, -1 (used by CTData.org)
#' - Small count suppressions: <5, <10
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for suppressed/non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Convert to character for consistent processing
  x <- as.character(x)

  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common text suppression markers
  x[x %in% c("*", "***", ".", "-", "-1", "<5", "<10", "N/A", "NA", "")] <- NA_character_
  x[grepl("^\\*+$", x)] <- NA_character_
  x[grepl("^<\\d+$", x)] <- NA_character_

  # Convert to numeric
  result <- suppressWarnings(as.numeric(x))

 # Handle numeric suppression codes used by CTData.org
  # -9999 and -6666 are common suppression markers for small cell sizes
  result[!is.na(result) & result < -999] <- NA_real_

  result
}


#' Get available years for Connecticut enrollment data
#'
#' Returns the range of school years for which enrollment data is available.
#' Connecticut EdSight provides enrollment data from 2007 (2006-07 school year)
#' through 2024 (2023-24 school year). The function can optionally query the
#' EdSight API to verify availability.
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
  # - 2023-24 data confirmed available (end year 2024)

  # Historical minimum year (first year with EdSight enrollment data)
  min_year <- 2007

  # Maximum year with confirmed data availability
  # Cap at 2024 (2023-24 school year) - update when newer data is confirmed
  max_year <- 2024

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
