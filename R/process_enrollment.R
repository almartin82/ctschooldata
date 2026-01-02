# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw enrollment data from
# Connecticut CSDE into a standardized format.
#
# ==============================================================================

#' Process raw enrollment data
#'
#' Transforms raw enrollment data from CSDE into standardized format.
#'
#' @param raw_data List of raw data frames from get_raw_enr()
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Check what data we have
  if (is.null(raw_data)) {
    stop("No raw data provided")
  }

  # If we have enrollment data from CTData or other source
  if (!is.null(raw_data$enrollment) && nrow(raw_data$enrollment) > 0) {
    return(process_ctdata_enrollment(raw_data$enrollment, end_year))
  }

  # If we only have organization directory
  if (!is.null(raw_data$organizations)) {
    return(process_org_directory(raw_data$organizations, end_year))
  }

  # Return empty structure
  create_empty_enrollment_df(end_year)
}


#' Process CTData.org enrollment data
#'
#' @param df Raw enrollment data frame from CTData
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_ctdata_enrollment <- function(df, end_year) {

  # CTData enrollment data typically has columns like:
  # - District, Town, Grade, Year, Value, FIPS

  # Standardize column names
  names(df) <- tolower(names(df))
  names(df) <- gsub(" ", "_", names(df))

  # Check which columns exist
  has_school_name <- "school_name" %in% names(df)
  has_district <- "district" %in% names(df)

  # Add placeholder columns if missing (to avoid case_when errors)
  if (!has_school_name) {
    df$school_name <- NA_character_
  }
  if (!has_district) {
    df$district <- NA_character_
  }

  # Create standardized output
  result <- df |>
    dplyr::mutate(
      end_year = end_year,
      type = dplyr::case_when(
        grepl("state", tolower(.data$district), fixed = TRUE) ~ "State",
        is.na(.data$school_name) | .data$school_name == "" ~ "District",
        TRUE ~ "Campus"
      )
    )

  # Rename columns to standard schema
  if ("district" %in% names(result)) {
    result <- dplyr::rename(result, district_name = district)
  }

  if ("school_name" %in% names(result)) {
    result <- dplyr::rename(result, campus_name = school_name)
  }

  if ("value" %in% names(result)) {
    result <- dplyr::rename(result, n_students = value)
    result$n_students <- safe_numeric(result$n_students)
  }

  result
}


#' Process organization directory data
#'
#' Creates enrollment structure from organization directory.
#' Note: This doesn't include actual enrollment counts.
#'
#' @param df Organization directory data frame
#' @param end_year School year end
#' @return Data frame with organization structure
#' @keywords internal
process_org_directory <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year))
  }

  # Standardize and process
  result <- df |>
    dplyr::mutate(
      end_year = end_year,
      type = dplyr::case_when(
        grepl("district", tolower(org_type), fixed = TRUE) ~ "District",
        grepl("school", tolower(org_type), fixed = TRUE) ~ "Campus",
        TRUE ~ "Other"
      ),
      district_id = dplyr::if_else(
        type == "District",
        org_code,
        NA_character_
      ),
      campus_id = dplyr::if_else(
        type == "Campus",
        org_code,
        NA_character_
      ),
      district_name = district_name,
      campus_name = dplyr::if_else(
        type == "Campus",
        school_name,
        NA_character_
      )
    )

  # Select and order columns
  result |>
    dplyr::select(
      end_year, type,
      district_id, campus_id,
      district_name, campus_name,
      dplyr::everything()
    )
}


#' Create empty enrollment data frame
#'
#' Returns an empty data frame with the standard schema.
#'
#' @param end_year School year end
#' @return Empty data frame with standard columns
#' @keywords internal
create_empty_enrollment_df <- function(end_year) {
  data.frame(
    end_year = integer(),
    type = character(),
    district_id = character(),
    campus_id = character(),
    district_name = character(),
    campus_name = character(),
    row_total = numeric(),
    stringsAsFactors = FALSE
  )
}


#' Standardize district/school identifiers
#'
#' Connecticut uses 7-digit organization codes.
#'
#' @param code Organization code
#' @return Standardized 7-character code
#' @keywords internal
standardize_org_code <- function(code) {
  code <- as.character(code)
  code <- gsub("[^0-9]", "", code)

  # Pad to 7 digits
  sprintf("%07d", as.integer(code))
}


#' Extract grade columns from enrollment data
#'
#' Identifies and standardizes grade-level columns.
#'
#' @param df Data frame with enrollment data
#' @return List with grade column names and mapping
#' @keywords internal
identify_grade_columns <- function(df) {

  # Common grade column patterns
  grade_patterns <- c(
    "pre.?k" = "grade_pk",
    "prek" = "grade_pk",
    "kindergarten|^k$" = "grade_k",
    "grade.?1$|^1st" = "grade_01",
    "grade.?2$|^2nd" = "grade_02",
    "grade.?3$|^3rd" = "grade_03",
    "grade.?4$|^4th" = "grade_04",
    "grade.?5$|^5th" = "grade_05",
    "grade.?6$|^6th" = "grade_06",
    "grade.?7$|^7th" = "grade_07",
    "grade.?8$|^8th" = "grade_08",
    "grade.?9$|^9th" = "grade_09",
    "grade.?10$|^10th" = "grade_10",
    "grade.?11$|^11th" = "grade_11",
    "grade.?12$|^12th" = "grade_12"
  )

  col_names <- tolower(names(df))
  mapping <- list()

  for (pattern in names(grade_patterns)) {
    matches <- grep(pattern, col_names, value = TRUE)
    if (length(matches) > 0) {
      mapping[[grade_patterns[pattern]]] <- matches[1]
    }
  }

  mapping
}
