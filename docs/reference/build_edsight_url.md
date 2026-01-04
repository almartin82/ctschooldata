# Build EdSight enrollment export URL

Constructs a URL for downloading enrollment data from EdSight. Note:
EdSight uses Qlik Sense which requires browser interaction for data
export. This function returns the dashboard URL.

## Usage

``` r
build_edsight_url(end_year)
```

## Arguments

- end_year:

  School year end

## Value

URL string
