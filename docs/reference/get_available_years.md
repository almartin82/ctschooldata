# Get available years for Connecticut enrollment data

Returns the range of school years for which enrollment data is
available. Connecticut EdSight provides enrollment data from 2007
(2006-07 school year) through 2024 (2023-24 school year). The function
can optionally query the EdSight API to verify availability.

## Usage

``` r
get_available_years(check_api = TRUE)
```

## Arguments

- check_api:

  If TRUE (default), queries the EdSight portal to detect available
  years. If FALSE, returns the known historical range.

## Value

Integer vector of available school years (end year)

## Examples

``` r
get_available_years()
#>  [1] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [16] 2022 2023 2024
```
