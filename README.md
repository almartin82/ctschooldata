# ctschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/ctschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/ctschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/ctschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/ctschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/ctschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/ctschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Fetch and analyze Connecticut school enrollment data from the Connecticut State Department of Education (CSDE) in R or Python.

**[Documentation](https://almartin82.github.io/ctschooldata/)** | **[Getting Started](https://almartin82.github.io/ctschooldata/articles/quickstart.html)**

## What can you find with ctschooldata?

**19 years of enrollment data (2007-2025).** 530,000 students across 170+ districts in the Constitution State. Here are ten stories hiding in the numbers:

---

### 1. Connecticut has lost 70,000 students

Connecticut public school enrollment peaked around 580,000 in 2006 and has been declining ever since. The state has lost more than 12% of its student population.

```r
library(ctschooldata)
library(dplyr)

enr <- fetch_enr_multi(2007:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students))
```

---

### 2. Hartford, Bridgeport, and New Haven anchor urban Connecticut

Connecticut's three largest cities serve over 60,000 students combined, with demographics and challenges quite different from wealthy suburbs.

```r
enr_2025 <- fetch_enr(2025)

enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Hartford|Bridgeport|New Haven", district_name)) %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students)
```

---

### 3. COVID hit Connecticut hard

Connecticut lost over 15,000 students between 2020 and 2022, with kindergarten seeing the sharpest drops.

```r
enr <- fetch_enr_multi(2019:2023)

enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09")) %>%
  select(end_year, grade_level, n_students) %>%
  tidyr::pivot_wider(names_from = grade_level, values_from = n_students)
```

---

### 4. The demographic crossover is coming

Hispanic students are now the second-largest group statewide and are on track to become the plurality within a decade as white enrollment declines.

```r
enr <- fetch_enr_multi(2007:2025)

enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white")) %>%
  select(end_year, subgroup, n_students, pct) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = c(n_students, pct))
```

---

### 5. Fairfield County is Connecticut's wealthiest--and whitest

Fairfield County districts like Greenwich, Darien, and New Canaan have demographics that look nothing like Hartford or Bridgeport, just miles away.

```r
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL",
         grepl("Greenwich|Darien|New Canaan|Westport", district_name),
         subgroup %in% c("white", "hispanic", "black", "asian")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, subgroup, pct) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = pct)
```

---

### 6. Magnet schools serve 35,000+ students

Connecticut's extensive interdistrict magnet school program is one of the largest in the nation, designed to promote integration across district lines.

```r
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Regional|CREC|Magnet|Interdistrict", district_name, ignore.case = TRUE)) %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, n_students)
```

---

### 7. Small towns are losing schools

Connecticut's smallest districts (under 1,000 students) face existential questions about whether they can sustain comprehensive K-12 programs.

```r
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  filter(n_students < 1000) %>%
  arrange(n_students) %>%
  head(15) %>%
  select(district_name, n_students)
```

---

### 8. English learners are 8% of enrollment

Connecticut's English learner population has grown significantly, concentrated in urban districts and some suburbs with recent immigration.

```r
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("lep", "total_enrollment")) %>%
  select(subgroup, n_students, pct)
```

---

### 9. Stamford is Connecticut's most diverse large city

Stamford Public Schools has a remarkably even distribution across racial groups, making it one of the most diverse districts in New England.

```r
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL",
         grepl("Stamford", district_name),
         subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(pct))
```

---

### 10. The achievement gap tracks the demographic divide

Connecticut has one of the nation's largest achievement gaps, mapping closely to the dramatic demographic differences between wealthy suburbs and urban cores.

```r
# Compare demographics between district types
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL",
         grepl("Hartford|Greenwich|Bridgeport|Darien", district_name),
         subgroup %in% c("total_enrollment", "hispanic", "white", "econ_disadv")) %>%
  select(district_name, subgroup, n_students, pct) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = c(n_students, pct))
```

---

## Enrollment Visualizations

<img src="https://almartin82.github.io/ctschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png" alt="Connecticut statewide enrollment trends" width="600">

<img src="https://almartin82.github.io/ctschooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png" alt="Top Connecticut districts" width="600">

See the [full vignette](https://almartin82.github.io/ctschooldata/articles/enrollment_hooks.html) for more insights.

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/ctschooldata")
```

## Quick Start

### R

```r
library(ctschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "hispanic", "black", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Python

```python
import pyctschooldata as ct

# Fetch 2025 data (2024-25 school year)
enr = ct.fetch_enr(2025)

# Statewide total
total = enr[(enr['is_state']) & (enr['subgroup'] == 'total_enrollment') & (enr['grade_level'] == 'TOTAL')]['n_students'].sum()
print(f"{total:,} students")
#> ~500,000 students

# Get multiple years
enr_multi = ct.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])

# Check available years
years = ct.get_available_years()
print(f"Data available: {years['min_year']}-{years['max_year']}")
#> Data available: 2007-2025
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2007-2025** | EdSight / CT Open Data | Full demographic and grade-level data |

Data is sourced from the Connecticut State Department of Education via EdSight and the CT Open Data portal.

### What's included

- **Levels:** State, district (~170), school (~1,000)
- **Demographics:** White, Black, Hispanic, Asian, American Indian, Pacific Islander, Two or More Races
- **Special populations:** English learners, free/reduced lunch, students with disabilities
- **Grade levels:** Pre-K through 12

### Caveats

- Some data may require manual export from EdSight
- Use `import_local_enr()` if automatic downloads fail

## Data source

Connecticut State Department of Education: [EdSight](https://public-edsight.ct.gov/)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
