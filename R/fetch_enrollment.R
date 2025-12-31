# ==============================================================================
# Enrollment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading enrollment data from the
# Connecticut State Department of Education (CSDE).
#
# ==============================================================================

#' Fetch Connecticut enrollment data
#'
#' Downloads and processes enrollment data from the Connecticut State
#' Department of Education (CSDE) via EdSight and the CT Open Data portal.
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2023-24
#'   school year is year '2024'. Valid values are 2007-2025.
#' @param tidy If TRUE (default), returns data in long (tidy) format with subgroup
#'   column. If FALSE, returns wide format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from CSDE.
#' @return Data frame with enrollment data. Wide format includes columns for
#'   district_id, campus_id, names, and enrollment counts by demographic/grade.
#'   Tidy format pivots these counts into subgroup and grade_level columns.
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 enrollment data (2023-24 school year)
#' enr_2024 <- fetch_enr(2024)
#'
#' # Get wide format
#' enr_wide <- fetch_enr(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' enr_fresh <- fetch_enr(2024, use_cache = FALSE)
#'
#' # Filter to Hartford Public Schools
#' hartford <- enr_2024 %>%
#'   dplyr::filter(grepl("Hartford", district_name))
#' }
fetch_enr <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available_years <- get_available_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between ", min(available_years), " and ", max(available_years), ". ",
      "Run get_available_years() to see available years."
    ))
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "tidy" else "wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from CSDE
  raw <- get_raw_enr(end_year)

  # Process to standard schema
  processed <- process_enr(raw, end_year)

  # Check if we got meaningful data
  if (is.null(processed) || nrow(processed) == 0) {
    warning(paste("No enrollment data found for", end_year, ".",
                  "Data may need to be downloaded manually from EdSight.",
                  "\nVisit: https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Public-School-Enrollment-Export"))
    return(processed)
  }

  # Optionally tidy
  if (tidy) {
    processed <- tidy_enr(processed) %>%
      id_enr_aggs()
  }

  # Cache the result
  if (use_cache && nrow(processed) > 0) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Fetch enrollment data for multiple years
#'
#' Downloads and combines enrollment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with enrollment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' enr_multi <- fetch_enr_multi(2022:2024)
#'
#' # Track enrollment trends
#' enr_multi %>%
#'   dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
#'   dplyr::select(end_year, n_students)
#' }
fetch_enr_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  available_years <- get_available_years()
  invalid_years <- end_years[!end_years %in% available_years]
  if (length(invalid_years) > 0) {
    stop(paste("Invalid years:", paste(invalid_years, collapse = ", "),
               "\nAvailable years:", paste(range(available_years), collapse = "-")))
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      fetch_enr(yr, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}


#' Import local enrollment data file
#'
#' Imports enrollment data from a locally downloaded Excel or CSV file.
#' This is useful when data must be manually exported from EdSight.
#'
#' @param file_path Path to local file (Excel or CSV)
#' @param end_year School year end for this data
#' @param tidy If TRUE (default), returns data in tidy format
#' @param save_to_cache If TRUE (default), saves processed data to cache
#' @return Processed enrollment data frame
#' @export
#' @examples
#' \dontrun{
#' # Import manually downloaded EdSight export
#' enr_2024 <- import_local_enr(
#'   "~/Downloads/CT_Enrollment_2023-24.xlsx",
#'   end_year = 2024
#' )
#' }
import_local_enr <- function(file_path, end_year, tidy = TRUE, save_to_cache = TRUE) {

  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Determine file type
  ext <- tolower(tools::file_ext(file_path))

  # Read file
  if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is required to read Excel files")
    }
    raw_df <- readxl::read_excel(file_path, col_types = "text")
  } else if (ext == "csv") {
    raw_df <- readr::read_csv(file_path, col_types = readr::cols(.default = "c"),
                               show_col_types = FALSE)
  } else {
    stop("Unsupported file type: ", ext, ". Use .xlsx, .xls, or .csv")
  }

  # Add end_year
  raw_df$end_year <- end_year

  # Process the data
  processed <- process_local_enrollment(raw_df, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_enr(processed) %>%
      id_enr_aggs()
  }

  # Cache if requested
  if (save_to_cache && nrow(processed) > 0) {
    cache_type <- if (tidy) "tidy" else "wide"
    write_cache(processed, end_year, cache_type)
    message(paste("Saved to cache for year", end_year))
  }

  processed
}


#' Process locally imported enrollment data
#'
#' Handles various formats of EdSight enrollment exports.
#'
#' @param df Raw data frame from file import
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_local_enrollment <- function(df, end_year) {

  # Standardize column names
  names(df) <- tolower(names(df))
  names(df) <- gsub("\\s+", "_", names(df))
  names(df) <- gsub("[^a-z0-9_]", "", names(df))

  # Common EdSight column mappings
  col_mapping <- c(
    "district" = "district_name",
    "district_name" = "district_name",
    "school" = "campus_name",
    "school_name" = "campus_name",
    "organization" = "campus_name",
    "district_code" = "district_id",
    "school_code" = "campus_id",
    "organization_code" = "org_code",
    "total" = "row_total",
    "total_enrollment" = "row_total",
    "count" = "n_students",
    "enrollment" = "n_students"
  )

  # Apply column mapping
  for (old_name in names(col_mapping)) {
    if (old_name %in% names(df) && !(col_mapping[old_name] %in% names(df))) {
      names(df)[names(df) == old_name] <- col_mapping[old_name]
    }
  }

  # Identify organization type
  df <- df %>%
    dplyr::mutate(
      type = dplyr::case_when(
        !is.na(campus_name) & campus_name != "" ~ "Campus",
        !is.na(district_name) & district_name != "" ~ "District",
        TRUE ~ "Other"
      ),
      end_year = as.integer(end_year)
    )

  # Convert numeric columns
  numeric_cols <- c("row_total", "n_students", grep("^grade_", names(df), value = TRUE))
  for (col in numeric_cols) {
    if (col %in% names(df)) {
      df[[col]] <- safe_numeric(df[[col]])
    }
  }

  # Calculate row_total if missing
  grade_cols <- grep("^grade_", names(df), value = TRUE)
  if (!"row_total" %in% names(df) && length(grade_cols) > 0) {
    df$row_total <- rowSums(df[, grade_cols], na.rm = TRUE)
  }

  df
}
