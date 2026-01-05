#' ctschooldata: Fetch and Process Connecticut School Data
#'
#' Downloads and processes school data from the Connecticut State Department
#' of Education (CSDE). Provides functions for fetching enrollment data from
#' EdSight and historical archives, transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{List available data years}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Connecticut uses organization codes for schools and districts:
#' \itemize{
#'   \item District Codes: 7 digits (e.g., 0010011 for Andover School District)
#'   \item School Codes: 7 digits (e.g., 0010111 for Andover Elementary School)
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Connecticut State Department of Education:
#' \itemize{
#'   \item EdSight Portal: \url{https://public-edsight.ct.gov/}
#'   \item Enrollment Dashboard: \url{https://public-edsight.ct.gov/students/enrollment-dashboard}
#'   \item CT Open Data: \url{https://data.ct.gov/}
#'   \item Historical Archive (1996-2009): \url{https://portal.ct.gov/sde/fiscal-services/student-counts}
#' }
#'
#' @section Data Availability:
#' \itemize{
#'   \item EdSight data: 2007-2025 (school years 2006-07 through 2024-25)
#'   \item Condition of Education Reports: 2004-05 through 2023-24
#'   \item Historical PDF/Excel: 1996-2009
#' }
#'
#' @docType package
#' @name ctschooldata-package
#' @aliases ctschooldata
#' @keywords internal
"_PACKAGE"

# Global variables to avoid R CMD check NOTEs
# These are column names used in dplyr operations
utils::globalVariables(c(
  ".", "address", "campus_id", "campus_name", "district", "district_id",
  "district_name", "grade_1", "grade_10", "grade_11", "grade_12", "grade_2",
  "grade_3", "grade_4", "grade_5", "grade_6", "grade_7", "grade_8", "grade_9",
  "grade_level", "grades_served", "kindergarten", "latitude", "longitude",
  "n_students", "name", "org_code", "org_type", "organization_code",
  "organization_type", "phone", "prekindergarten", "row_total", "school_name",
  "state_district_id", "subgroup", "town", "type", "value", "zipcode"
))

