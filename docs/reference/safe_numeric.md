# Convert to numeric, handling suppression markers

CSDE and CTData.org use various markers for suppressed data:

- Text markers: \*, \*\*\*, ., -, N/A, NA, empty string

- Numeric suppression codes: -9999, -6666, -1 (used by CTData.org)

- Small count suppressions: \<5, \<10

## Usage

``` r
safe_numeric(x)
```

## Arguments

- x:

  Vector to convert

## Value

Numeric vector with NA for suppressed/non-numeric values
