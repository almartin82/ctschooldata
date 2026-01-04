# Import local enrollment data file

Imports enrollment data from a locally downloaded Excel or CSV file.
This is useful when data must be manually exported from EdSight.

## Usage

``` r
import_local_enr(file_path, end_year, tidy = TRUE, save_to_cache = TRUE)
```

## Arguments

- file_path:

  Path to local file (Excel or CSV)

- end_year:

  School year end for this data

- tidy:

  If TRUE (default), returns data in tidy format

- save_to_cache:

  If TRUE (default), saves processed data to cache

## Value

Processed enrollment data frame

## Examples

``` r
if (FALSE) { # \dontrun{
# Import manually downloaded EdSight export
enr_2024 <- import_local_enr(
  "~/Downloads/CT_Enrollment_2023-24.xlsx",
  end_year = 2024
)
} # }
```
