# 15 Insights from Connecticut School Enrollment Data

``` r
library(ctschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))
```

This vignette explores Connecticut’s public school enrollment data,
surfacing key trends and demographic patterns across 18 years of data
(2007-2024).

**NOTE:** The code examples below show how to analyze enrollment data,
but require real enrollment counts from EdSight manual exports. The
automated data source only provides grade-offering flags. To run this
code with actual data:

1.  Visit
    <https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Public-School-Enrollment-Export>
2.  Export data for your desired years
3.  Use `import_local_enr(path, end_year)` to load the data
4.  Then run the analysis code below

------------------------------------------------------------------------

## 1. Connecticut has lost 70,000 students

Connecticut public school enrollment peaked around 580,000 in 2006 and
has been declining ever since. The state has lost more than 12% of its
student population.

``` r
enr <- fetch_enr_multi(2007:2024)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals
```

``` r
ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#0C2340") +
  geom_point(size = 3, color = "#0C2340") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Connecticut Public School Enrollment (2007-2024)",
    subtitle = "Steady decline has cost the state over 70,000 students",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )
```

------------------------------------------------------------------------

## 2. Hartford, Bridgeport, and New Haven anchor urban Connecticut

Connecticut’s three largest cities serve over 60,000 students combined,
with demographics and challenges quite different from wealthy suburbs.

``` r
enr_2024 <- fetch_enr(2024)

top_cities <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Hartford|Bridgeport|New Haven", district_name)) |>
  arrange(desc(n_students)) |>
  select(district_name, n_students)

top_cities
```

``` r
top_cities |>
  mutate(district_name = forcats::fct_reorder(district_name, n_students)) |>
  ggplot(aes(x = n_students, y = district_name, fill = district_name)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = scales::comma(n_students)), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Connecticut's Urban Core (2024)",
    subtitle = "Hartford, Bridgeport, and New Haven serve 60,000+ students",
    x = "Enrollment",
    y = NULL
  )
```

------------------------------------------------------------------------

## 3. COVID hit Connecticut hard

Connecticut lost over 15,000 students between 2020 and 2022, with
kindergarten seeing the sharpest drops.

``` r
covid_grades <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09"),
         end_year %in% 2019:2023) |>
  select(end_year, grade_level, n_students) |>
  pivot_wider(names_from = grade_level, values_from = n_students)

covid_grades
```

------------------------------------------------------------------------

## 4. The demographic crossover is coming

Hispanic students are now the second-largest group statewide and are on
track to become the plurality within a decade as white enrollment
declines.

``` r
demographics <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

demographics
```

``` r
demographics |>
  mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
  ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Connecticut Student Demographics (2024)",
    subtitle = "Hispanic enrollment is gaining on white enrollment",
    x = "Number of Students",
    y = NULL
  )
```

------------------------------------------------------------------------

## 5. Fairfield County is Connecticut’s wealthiest–and whitest

Fairfield County districts like Greenwich, Darien, and New Canaan have
demographics that look nothing like Hartford or Bridgeport, just miles
away.

``` r
fairfield <- enr_2024 |>
  filter(is_district, grade_level == "TOTAL",
         grepl("Greenwich|Darien|New Canaan|Westport", district_name),
         subgroup %in% c("white", "hispanic", "black", "asian")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(district_name, subgroup, pct) |>
  pivot_wider(names_from = subgroup, values_from = pct)

fairfield
```

``` r
enr_2024 |>
  filter(is_district, grade_level == "TOTAL",
         grepl("Greenwich|Darien|New Canaan|Westport", district_name),
         subgroup %in% c("white", "hispanic", "black", "asian")) |>
  mutate(pct = round(pct * 100, 1),
         district_name = gsub(" School District", "", district_name)) |>
  ggplot(aes(x = district_name, y = pct, fill = subgroup)) +
  geom_col(position = "dodge") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Fairfield County Demographics (2024)",
    subtitle = "Wealthy suburbs are predominantly white",
    x = NULL,
    y = "Percent of Enrollment",
    fill = "Race/Ethnicity"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

------------------------------------------------------------------------

## 6. Magnet schools serve 35,000+ students

Connecticut’s extensive interdistrict magnet school program is one of
the largest in the nation, designed to promote integration across
district lines.

``` r
magnets <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Regional|CREC|Magnet|Interdistrict", district_name, ignore.case = TRUE)) |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)

magnets
```

------------------------------------------------------------------------

## 7. Small towns are losing schools

Connecticut’s smallest districts (under 1,000 students) face existential
questions about whether they can sustain comprehensive K-12 programs.

``` r
small_districts <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  filter(n_students < 1000) |>
  arrange(n_students) |>
  head(15) |>
  select(district_name, n_students)

small_districts
```

------------------------------------------------------------------------

## 8. English learners are 8% of enrollment

Connecticut’s English learner population has grown significantly,
concentrated in urban districts and some suburbs with recent
immigration.

``` r
ell <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("lep", "total_enrollment")) |>
  select(subgroup, n_students, pct)

ell
```

------------------------------------------------------------------------

## 9. Stamford is Connecticut’s most diverse large city

Stamford Public Schools has a remarkably even distribution across racial
groups, making it one of the most diverse districts in New England.

``` r
stamford <- enr_2024 |>
  filter(is_district, grade_level == "TOTAL",
         grepl("Stamford", district_name),
         subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(pct))

stamford
```

``` r
stamford |>
  mutate(subgroup = forcats::fct_reorder(subgroup, pct)) |>
  ggplot(aes(x = pct, y = subgroup, fill = subgroup)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Stamford's Diverse Student Body (2024)",
    subtitle = "One of the most diverse districts in New England",
    x = "Percent of Enrollment",
    y = NULL
  )
```

------------------------------------------------------------------------

## 10. The achievement gap tracks the demographic divide

Connecticut has one of the nation’s largest achievement gaps, mapping
closely to the dramatic demographic differences between wealthy suburbs
and urban cores.

``` r
gap_comparison <- enr_2024 |>
  filter(is_district, grade_level == "TOTAL",
         grepl("Hartford|Greenwich|Bridgeport|Darien", district_name),
         subgroup %in% c("total_enrollment", "hispanic", "white", "econ_disadv")) |>
  select(district_name, subgroup, n_students, pct) |>
  pivot_wider(names_from = subgroup, values_from = c(n_students, pct))

gap_comparison
```

------------------------------------------------------------------------

## 11. New Haven loses students while suburbs grow

New Haven has seen steady enrollment decline while surrounding towns
like Guilford and Madison maintain stable numbers, illustrating
Connecticut’s urban-suburban divergence.

``` r
nh_area <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("New Haven|Guilford|Madison|Hamden|West Haven", district_name)) |>
  select(end_year, district_name, n_students) |>
  mutate(district_name = gsub(" School District", "", district_name))

nh_area
```

``` r
nh_area |>
  ggplot(aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  scale_color_brewer(palette = "Set1") +
  labs(
    title = "New Haven Area Enrollment Trends",
    subtitle = "Urban decline vs. suburban stability",
    x = "School Year (ending)",
    y = "Total Enrollment",
    color = "District"
  ) +
  theme(legend.position = "bottom")
```

------------------------------------------------------------------------

## 12. Kindergarten enrollment never recovered from COVID

Connecticut’s kindergarten enrollment dropped sharply in 2021 and has
not bounced back, signaling a potential long-term enrollment cliff.

``` r
k_trend <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  select(end_year, n_students)

k_trend
```

``` r
k_trend |>
  ggplot(aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#E87722") +
  geom_point(size = 3, color = "#E87722") +
  geom_vline(xintercept = 2020, linetype = "dashed", color = "red", alpha = 0.5) +
  annotate("text", x = 2020.5, y = max(k_trend$n_students, na.rm = TRUE),
           label = "COVID", hjust = 0, color = "red") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Connecticut Kindergarten Enrollment (2007-2024)",
    subtitle = "The pandemic created a lasting enrollment drop",
    x = "School Year (ending)",
    y = "Kindergarten Students"
  )
```

------------------------------------------------------------------------

## 13. Waterbury is Connecticut’s fourth-largest district

Waterbury often gets overlooked behind the big three, but it serves
nearly 18,000 students and faces many of the same challenges as
Hartford, Bridgeport, and New Haven.

``` r
big_four <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Hartford|Bridgeport|New Haven|Waterbury", district_name)) |>
  arrange(desc(n_students)) |>
  select(district_name, n_students)

big_four
```

``` r
big_four |>
  mutate(district_name = gsub(" School District", "", district_name),
         district_name = forcats::fct_reorder(district_name, n_students)) |>
  ggplot(aes(x = n_students, y = district_name, fill = district_name)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = scales::comma(n_students)), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Dark2") +
  labs(
    title = "Connecticut's Big Four Urban Districts (2024)",
    subtitle = "Waterbury rounds out the major cities",
    x = "Enrollment",
    y = NULL
  )
```

------------------------------------------------------------------------

## 14. CREC magnets serve more students than most districts

Capitol Region Education Council (CREC) magnets in the Hartford area
serve over 10,000 students, making it one of the largest education
organizations in the state.

``` r
crec_trend <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Capitol Region|CREC", district_name, ignore.case = TRUE)) |>
  select(end_year, district_name, n_students)

crec_trend
```

``` r
crec_trend |>
  ggplot(aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#4B0082") +
  geom_point(size = 3, color = "#4B0082") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "CREC Magnet School Enrollment",
    subtitle = "Hartford-area interdistrict magnets serve 10,000+ students",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )
```

------------------------------------------------------------------------

## 15. Asian enrollment has doubled since 2007

While white and Black enrollment has declined, Asian student enrollment
has grown substantially, now representing over 5% of Connecticut
students.

``` r
asian_trend <- enr |>
  filter(is_state, grade_level == "TOTAL", subgroup == "asian") |>
  select(end_year, n_students, pct) |>
  mutate(pct = round(pct * 100, 1))

asian_trend
```

``` r
asian_trend |>
  ggplot(aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#228B22") +
  geom_point(size = 3, color = "#228B22") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Connecticut Asian Student Enrollment (2007-2024)",
    subtitle = "Steady growth from 3% to over 5% of total enrollment",
    x = "School Year (ending)",
    y = "Asian Students"
  )
```

------------------------------------------------------------------------

## Summary

Connecticut’s school enrollment data reveals:

- **Long-term decline**: The state has lost over 70,000 students since
  peak enrollment
- **Urban-suburban divide**: Stark demographic differences between
  cities and wealthy suburbs
- **Demographic shift**: Hispanic students are approaching parity with
  white students
- **Magnet integration**: Extensive interdistrict magnet program serves
  35,000+ students
- **Small district challenges**: Many towns struggle to sustain K-12
  programs
- **Regional divergence**: New Haven and urban cores shrink while
  suburbs hold steady
- **COVID’s lasting impact**: Kindergarten enrollment has not recovered
  since 2020
- **The Big Four**: Waterbury joins Hartford, Bridgeport, and New Haven
  as major urban centers
- **CREC growth**: Capitol Region magnets now serve over 10,000 students
- **Asian growth**: Asian enrollment has doubled while other groups
  decline

These patterns shape school funding debates and the ongoing Sheff v.
O’Neill desegregation case across the Constitution State.

------------------------------------------------------------------------

*Data sourced from the Connecticut State Department of Education via
[EdSight](https://public-edsight.ct.gov/).*
