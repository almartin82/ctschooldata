# ctschooldata: Fetch and Process Connecticut School Data

Downloads and processes school data from the Connecticut State
Department of Education (CSDE). Provides functions for fetching
enrollment data from EdSight and historical archives, transforming it
into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/ctschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/ctschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/ctschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/ctschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/ctschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/ctschooldata/reference/get_available_years.md):

  List available data years

## Cache functions

- [`cache_status`](https://almartin82.github.io/ctschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/ctschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Connecticut uses organization codes for schools and districts:

- District Codes: 7 digits (e.g., 0010011 for Andover School District)

- School Codes: 7 digits (e.g., 0010111 for Andover Elementary School)

## Data Sources

Data is sourced from the Connecticut State Department of Education:

- EdSight Portal: <https://public-edsight.ct.gov/>

- Enrollment Dashboard:
  <https://public-edsight.ct.gov/students/enrollment-dashboard>

- CT Open Data: <https://data.ct.gov/>

- Historical Archive (1996-2009):
  <https://portal.ct.gov/sde/fiscal-services/student-counts>

## Data Availability

- EdSight data: 2007-2025 (school years 2006-07 through 2024-25)

- Condition of Education Reports: 2004-05 through 2023-24

- Historical PDF/Excel: 1996-2009

## See also

Useful links:

- <https://almartin82.github.io/ctschooldata>

- <https://github.com/almartin82/ctschooldata>

- Report bugs at <https://github.com/almartin82/ctschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
