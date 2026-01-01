# pyctschooldata

Python wrapper for Connecticut school enrollment data.

This is a thin rpy2 wrapper around the [ctschooldata](https://github.com/almartin82/ctschooldata) R package. It provides the same functionality but returns pandas DataFrames.

## Requirements

- Python 3.9+
- R 4.0+
- The `ctschooldata` R package installed

## Installation

```bash
# First, install the R package
# In R:
# remotes::install_github("almartin82/ctschooldata")

# Then install the Python package
pip install pyctschooldata
```

## Quick Start

```python
import pyctschooldata as ct

# Check available years
years = ct.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
df = ct.fetch_enr(2025)

# Fetch multiple years
df_multi = ct.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])

# Convert to tidy format
tidy = ct.tidy_enr(df)
```

## API

### `fetch_enr(end_year: int) -> pd.DataFrame`

Fetch enrollment data for a single school year.

### `fetch_enr_multi(end_years: list[int]) -> pd.DataFrame`

Fetch enrollment data for multiple school years.

### `tidy_enr(df: pd.DataFrame) -> pd.DataFrame`

Convert enrollment data to tidy (long) format.

### `get_available_years() -> dict`

Get the range of available years (`min_year`, `max_year`).

## Part of the 50 State Schooldata Family

This package is part of a family of packages providing school enrollment data for all 50 US states.

**See also:** [njschooldata](https://github.com/almartin82/njschooldata)

## License

MIT
