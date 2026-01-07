# Process organization directory data

Creates enrollment structure from organization directory. NOTE: This
processes the Education Directory which contains binary grade-offering
flags (0 = not offered, 1 = offered), NOT actual enrollment counts.

## Usage

``` r
process_org_directory(df, end_year)
```

## Arguments

- df:

  Organization directory data frame

- end_year:

  School year end

## Value

Data frame with grade-offering flags in tidy format
