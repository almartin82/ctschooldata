# Tidy enrollment data

Transforms wide enrollment data to long format with subgroup column.
Also handles data that is already in a semi-tidy format (e.g.,
CTData.org data which has n_students and grade_level columns already).

## Usage

``` r
tidy_enr(df)
```

## Arguments

- df:

  A wide data.frame of processed enrollment data

## Value

A long data.frame of tidied enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
wide_data <- fetch_enr(2024, tidy = FALSE)
tidy_data <- tidy_enr(wide_data)
} # }
```
