# ==============================================================================
# Enrollment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for transforming enrollment data from wide
# format to long (tidy) format and identifying aggregation levels.
#
# ==============================================================================

#' Tidy enrollment data
#'
#' Transforms wide enrollment data to long format with subgroup column.
#' Also handles data that is already in a semi-tidy format (e.g., CTData.org data
#' which has n_students and grade_level columns already).
#'
#' @param df A wide data.frame of processed enrollment data
#' @return A long data.frame of tidied enrollment data
#' @export
#' @examples
#' \dontrun{
#' wide_data <- fetch_enr(2024, tidy = FALSE)
#' tidy_data <- tidy_enr(wide_data)
#' }
tidy_enr <- function(df) {

  # Check if data is already in tidy format (has n_students AND grade_level columns)
  # This is the case for CTData.org data which comes pre-pivoted
  if ("n_students" %in% names(df) && "grade_level" %in% names(df)) {
    return(tidy_pretidied_data(df))
  }

  # Otherwise, process as wide format data
  tidy_wide_data(df)
}


#' Tidy pre-tidied enrollment data
#'
#' Handles data that is already in a semi-tidy format (e.g., CTData.org data).
#'
#' @param df Data frame with n_students and grade_level columns already present
#' @return Standardized tidy data frame
#' @keywords internal
tidy_pretidied_data <- function(df) {

  # PRD-required columns only
  prd_cols <- c(
    "end_year", "type",
    "district_id", "campus_id",
    "district_name", "campus_name",
    "grade_level", "subgroup", "n_students", "pct"
  )
  prd_cols <- prd_cols[prd_cols %in% names(df)]

  # Add subgroup column if missing (default to total_enrollment)
  if (!"subgroup" %in% names(df)) {
    df$subgroup <- "total_enrollment"
  }

  # Add pct column if missing
  if (!"pct" %in% names(df)) {
    df$pct <- NA_real_
  }

  # Add aggregation_flag column
  # Handle different column naming conventions (PRD uses district_id/campus_id,
  # some states use state_district_id/state_school_id)
  has_prd_ids <- "district_id" %in% names(df) && "campus_id" %in% names(df)
  has_state_ids <- "state_district_id" %in% names(df) && "state_school_id" %in% names(df)

  if (has_prd_ids) {
    df <- df |>
      dplyr::mutate(
        aggregation_flag = dplyr::case_when(
          !is.na(district_id) & !is.na(campus_id) & district_id != "" & campus_id != "" ~ "campus",
          !is.na(district_id) & district_id != "" ~ "district",
          TRUE ~ "state"
        )
      )
  } else if (has_state_ids) {
    df <- df |>
      dplyr::mutate(
        aggregation_flag = dplyr::case_when(
          !is.na(state_district_id) & !is.na(state_school_id) & state_district_id != "" & state_school_id != "" ~ "campus",
          !is.na(state_district_id) & state_district_id != "" ~ "district",
          TRUE ~ "state"
        )
      )
  } else {
    df$aggregation_flag <- "state"
  }

  # Select only PRD-required columns plus aggregation_flag
  df |>
    dplyr::select(dplyr::all_of(c(prd_cols, "aggregation_flag"))) |>
    dplyr::filter(!is.na(n_students))
}


#' Tidy wide-format enrollment data
#'
#' Transforms wide enrollment data to long format with subgroup column.
#'
#' @param df A wide data.frame with demographic columns and grade_XX columns
#' @return A long data.frame of tidied enrollment data
#' @keywords internal
tidy_wide_data <- function(df) {

  # PRD-required invariant columns
  invariants <- c(
    "end_year", "type",
    "district_id", "campus_id",
    "district_name", "campus_name"
  )
  invariants <- invariants[invariants %in% names(df)]

  # Demographic subgroups to tidy
  demo_cols <- c(
    "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "american_indian", "two_or_more"
  )
  demo_cols <- demo_cols[demo_cols %in% names(df)]

  # Special population subgroups
  special_cols <- c(
    "special_ed", "lep", "econ_disadv",
    "ell", "free_reduced_lunch", "sped"
  )
  special_cols <- special_cols[special_cols %in% names(df)]

  # Grade-level columns
  grade_cols <- grep("^grade_", names(df), value = TRUE)

  all_subgroups <- c(demo_cols, special_cols)

  # Transform demographic/special subgroups to long format
  if (length(all_subgroups) > 0) {
    has_row_total <- "row_total" %in% names(df)
    tidy_subgroups <- purrr::map_df(
      all_subgroups,
      function(.x) {
        result <- df |>
          dplyr::rename(n_students = dplyr::all_of(.x)) |>
          dplyr::select(dplyr::all_of(c(invariants, "n_students")),
                        dplyr::any_of("row_total")) |>
          dplyr::mutate(
            subgroup = .x,
            grade_level = "TOTAL"
          )
        if (has_row_total) {
          result <- result |> dplyr::mutate(pct = n_students / row_total)
        } else {
          result <- result |> dplyr::mutate(pct = NA_real_)
        }
        result |>
          dplyr::select(dplyr::all_of(c(invariants, "grade_level", "subgroup", "n_students", "pct")))
      }
    )
  } else {
    tidy_subgroups <- NULL
  }

  # Extract total enrollment as a "subgroup"
  if ("row_total" %in% names(df)) {
    tidy_total <- df |>
      dplyr::select(dplyr::all_of(c(invariants, "row_total"))) |>
      dplyr::mutate(
        n_students = row_total,
        subgroup = "total_enrollment",
        pct = 1.0,
        grade_level = "TOTAL"
      ) |>
      dplyr::select(dplyr::all_of(c(invariants, "grade_level", "subgroup", "n_students", "pct")))
  } else if ("n_students" %in% names(df)) {
    tidy_total <- df |>
      dplyr::select(dplyr::all_of(c(invariants, "n_students"))) |>
      dplyr::mutate(
        subgroup = "total_enrollment",
        pct = 1.0,
        grade_level = "TOTAL"
      ) |>
      dplyr::select(dplyr::all_of(c(invariants, "grade_level", "subgroup", "n_students", "pct")))
  } else {
    tidy_total <- NULL
  }

  # Transform grade-level enrollment to long format
  if (length(grade_cols) > 0) {
    grade_level_map <- c(
      "grade_pk" = "PK",
      "grade_k" = "K",
      "grade_01" = "01",
      "grade_02" = "02",
      "grade_03" = "03",
      "grade_04" = "04",
      "grade_05" = "05",
      "grade_06" = "06",
      "grade_07" = "07",
      "grade_08" = "08",
      "grade_09" = "09",
      "grade_10" = "10",
      "grade_11" = "11",
      "grade_12" = "12"
    )

    has_row_total_grades <- "row_total" %in% names(df)
    tidy_grades <- purrr::map_df(
      grade_cols,
      function(.x) {
        gl <- grade_level_map[.x]
        if (is.na(gl)) gl <- .x

        result <- df |>
          dplyr::rename(n_students = dplyr::all_of(.x)) |>
          dplyr::select(dplyr::all_of(c(invariants, "n_students")),
                        dplyr::any_of("row_total")) |>
          dplyr::mutate(
            subgroup = "total_enrollment",
            grade_level = gl
          )
        if (has_row_total_grades) {
          result <- result |> dplyr::mutate(pct = n_students / row_total)
        } else {
          result <- result |> dplyr::mutate(pct = NA_real_)
        }
        result |>
          dplyr::select(dplyr::all_of(c(invariants, "grade_level", "subgroup", "n_students", "pct")))
      }
    )
  } else {
    tidy_grades <- NULL
  }

  # Combine all tidy data
  result <- dplyr::bind_rows(tidy_total, tidy_subgroups, tidy_grades) |>
    dplyr::filter(!is.na(n_students))

  # Add aggregation_flag column
  # Handle different column naming conventions
  has_prd_ids <- "district_id" %in% names(result) && "campus_id" %in% names(result)
  has_state_ids <- "state_district_id" %in% names(result) && "state_school_id" %in% names(result)

  if (has_prd_ids) {
    result <- result |>
      dplyr::mutate(
        aggregation_flag = dplyr::case_when(
          !is.na(district_id) & !is.na(campus_id) & district_id != "" & campus_id != "" ~ "campus",
          !is.na(district_id) & district_id != "" ~ "district",
          TRUE ~ "state"
        )
      )
  } else if (has_state_ids) {
    result <- result |>
      dplyr::mutate(
        aggregation_flag = dplyr::case_when(
          !is.na(state_district_id) & !is.na(state_school_id) & state_district_id != "" & state_school_id != "" ~ "campus",
          !is.na(state_district_id) & state_district_id != "" ~ "district",
          TRUE ~ "state"
        )
      )
  } else {
    result$aggregation_flag <- "state"
  }

  result
}


#' Identify enrollment aggregation levels
#'
#' Adds boolean flags to identify state, district, and campus level records.
#'
#' @param df Enrollment dataframe, output of tidy_enr
#' @return data.frame with boolean aggregation flags
#' @export
#' @examples
#' \dontrun{
#' tidy_data <- fetch_enr(2024)
#' # Data already has aggregation flags via id_enr_aggs
#' table(tidy_data$is_state, tidy_data$is_district, tidy_data$is_campus)
#' }
id_enr_aggs <- function(df) {
  has_org_type <- "org_type" %in% names(df)
  has_campus_name <- "campus_name" %in% names(df)

  # Add placeholder columns if missing (only for internal use)
  if (!has_campus_name) {
    df$campus_name <- NA_character_
  }
  if (!has_org_type) {
    df$org_type <- NA_character_
  }

  # Calculate is_* flags
  result <- df |>
    dplyr::mutate(
      # State level: Type == "State"
      is_state = type == "State",

      # District level: Type == "District"
      is_district = type == "District",

      # Campus level: Type == "Campus"
      is_campus = type == "Campus",

      # Charter detection - look for charter in org_type or name
      is_charter = dplyr::case_when(
        !is.na(org_type) & grepl("charter", tolower(org_type)) ~ TRUE,
        !is.na(campus_name) & grepl("charter", tolower(campus_name)) ~ TRUE,
        TRUE ~ FALSE
      )
    )

  # Add aggregation_flag based on ID presence
  # Handle different column naming conventions
  has_prd_ids <- "district_id" %in% names(df) && "campus_id" %in% names(df)
  has_state_ids <- "state_district_id" %in% names(df) && "state_school_id" %in% names(df)

  if (has_prd_ids) {
    result <- result |>
      dplyr::mutate(
        aggregation_flag = dplyr::case_when(
          !is.na(district_id) & !is.na(campus_id) & district_id != "" & campus_id != "" ~ "campus",
          !is.na(district_id) & district_id != "" ~ "district",
          TRUE ~ "state"
        )
      )
  } else if (has_state_ids) {
    result <- result |>
      dplyr::mutate(
        aggregation_flag = dplyr::case_when(
          !is.na(state_district_id) & !is.na(state_school_id) & state_district_id != "" & state_school_id != "" ~ "campus",
          !is.na(state_district_id) & state_district_id != "" ~ "district",
          TRUE ~ "state"
        )
      )
  } else {
    result$aggregation_flag <- "state"
  }

  # Remove org_type if it wasn't in the original data (PRD doesn't require it)
  if (!has_org_type) {
    result <- result |> dplyr::select(-dplyr::any_of("org_type"))
  }

  result
}


#' Custom Enrollment Grade Level Aggregates
#'
#' Creates aggregations for common grade groupings: K-8, 9-12 (HS), K-12.
#'
#' @param df A tidy enrollment df
#' @return df of aggregated enrollment data
#' @export
#' @examples
#' \dontrun{
#' tidy_data <- fetch_enr(2024)
#' grade_aggs <- enr_grade_aggs(tidy_data)
#' }
enr_grade_aggs <- function(df) {

  # Group by invariants (everything except grade_level and counts)
  group_vars <- c(
    "end_year", "type",
    "district_id", "campus_id",
    "district_name", "campus_name",
    "town", "org_code", "org_type",
    "subgroup",
    "is_state", "is_district", "is_campus", "is_charter"
  )
  group_vars <- group_vars[group_vars %in% names(df)]

  # K-8 aggregate
  k8_agg <- df |>
    dplyr::filter(
      subgroup == "total_enrollment",
      grade_level %in% c("K", "01", "02", "03", "04", "05", "06", "07", "08")
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) |>
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      grade_level = "K8",
      pct = NA_real_
    )

  # High school (9-12) aggregate
  hs_agg <- df |>
    dplyr::filter(
      subgroup == "total_enrollment",
      grade_level %in% c("09", "10", "11", "12")
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) |>
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      grade_level = "HS",
      pct = NA_real_
    )

  # K-12 aggregate (excludes PK)
  k12_agg <- df |>
    dplyr::filter(
      subgroup == "total_enrollment",
      grade_level %in% c("K", "01", "02", "03", "04", "05", "06", "07", "08",
                         "09", "10", "11", "12")
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) |>
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      grade_level = "K12",
      pct = NA_real_
    )

  dplyr::bind_rows(k8_agg, hs_agg, k12_agg)
}
