## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE,
  fig.width = 8,
  fig.height = 5,
  eval = FALSE
)

## ----load-packages------------------------------------------------------------
# library(ctschooldata)
# library(dplyr)
# library(tidyr)
# library(ggplot2)
# 
# theme_set(theme_minimal(base_size = 14))

## ----statewide-trend----------------------------------------------------------
# enr <- fetch_enr_multi(2007:2025)
# 
# state_totals <- enr |>
#   filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#   select(end_year, n_students) |>
#   mutate(change = n_students - lag(n_students),
#          pct_change = round(change / lag(n_students) * 100, 2))
# 
# state_totals

## ----statewide-chart----------------------------------------------------------
# ggplot(state_totals, aes(x = end_year, y = n_students)) +
#   geom_line(linewidth = 1.2, color = "#0C2340") +
#   geom_point(size = 3, color = "#0C2340") +
#   scale_y_continuous(labels = scales::comma) +
#   labs(
#     title = "Connecticut Public School Enrollment (2007-2025)",
#     subtitle = "Steady decline has cost the state over 70,000 students",
#     x = "School Year (ending)",
#     y = "Total Enrollment"
#   )

## ----top-districts------------------------------------------------------------
# enr_2025 <- fetch_enr(2025)
# 
# top_cities <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Hartford|Bridgeport|New Haven", district_name)) |>
#   arrange(desc(n_students)) |>
#   select(district_name, n_students)
# 
# top_cities

## ----top-districts-chart------------------------------------------------------
# top_cities |>
#   mutate(district_name = forcats::fct_reorder(district_name, n_students)) |>
#   ggplot(aes(x = n_students, y = district_name, fill = district_name)) +
#   geom_col(show.legend = FALSE) +
#   geom_text(aes(label = scales::comma(n_students)), hjust = -0.1) +
#   scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
#   scale_fill_brewer(palette = "Set2") +
#   labs(
#     title = "Connecticut's Urban Core (2025)",
#     subtitle = "Hartford, Bridgeport, and New Haven serve 60,000+ students",
#     x = "Enrollment",
#     y = NULL
#   )

## ----covid-impact-------------------------------------------------------------
# covid_grades <- enr |>
#   filter(is_state, subgroup == "total_enrollment",
#          grade_level %in% c("K", "01", "06", "09"),
#          end_year %in% 2019:2023) |>
#   select(end_year, grade_level, n_students) |>
#   pivot_wider(names_from = grade_level, values_from = n_students)
# 
# covid_grades

## ----demographics-------------------------------------------------------------
# demographics <- enr_2025 |>
#   filter(is_state, grade_level == "TOTAL",
#          subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) |>
#   mutate(pct = round(pct * 100, 1)) |>
#   select(subgroup, n_students, pct) |>
#   arrange(desc(n_students))
# 
# demographics

## ----demographics-chart-------------------------------------------------------
# demographics |>
#   mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
#   ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
#   geom_col(show.legend = FALSE) +
#   geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
#   scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
#   scale_fill_brewer(palette = "Set2") +
#   labs(
#     title = "Connecticut Student Demographics (2025)",
#     subtitle = "Hispanic enrollment is gaining on white enrollment",
#     x = "Number of Students",
#     y = NULL
#   )

## ----fairfield----------------------------------------------------------------
# fairfield <- enr_2025 |>
#   filter(is_district, grade_level == "TOTAL",
#          grepl("Greenwich|Darien|New Canaan|Westport", district_name),
#          subgroup %in% c("white", "hispanic", "black", "asian")) |>
#   mutate(pct = round(pct * 100, 1)) |>
#   select(district_name, subgroup, pct) |>
#   pivot_wider(names_from = subgroup, values_from = pct)
# 
# fairfield

## ----fairfield-chart----------------------------------------------------------
# enr_2025 |>
#   filter(is_district, grade_level == "TOTAL",
#          grepl("Greenwich|Darien|New Canaan|Westport", district_name),
#          subgroup %in% c("white", "hispanic", "black", "asian")) |>
#   mutate(pct = round(pct * 100, 1),
#          district_name = gsub(" School District", "", district_name)) |>
#   ggplot(aes(x = district_name, y = pct, fill = subgroup)) +
#   geom_col(position = "dodge") +
#   scale_fill_brewer(palette = "Set2") +
#   labs(
#     title = "Fairfield County Demographics (2025)",
#     subtitle = "Wealthy suburbs are predominantly white",
#     x = NULL,
#     y = "Percent of Enrollment",
#     fill = "Race/Ethnicity"
#   ) +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1))

## ----magnets------------------------------------------------------------------
# magnets <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Regional|CREC|Magnet|Interdistrict", district_name, ignore.case = TRUE)) |>
#   arrange(desc(n_students)) |>
#   head(10) |>
#   select(district_name, n_students)
# 
# magnets

## ----small-districts----------------------------------------------------------
# small_districts <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#   filter(n_students < 1000) |>
#   arrange(n_students) |>
#   head(15) |>
#   select(district_name, n_students)
# 
# small_districts

## ----ell----------------------------------------------------------------------
# ell <- enr_2025 |>
#   filter(is_state, grade_level == "TOTAL",
#          subgroup %in% c("lep", "total_enrollment")) |>
#   select(subgroup, n_students, pct)
# 
# ell

## ----stamford-----------------------------------------------------------------
# stamford <- enr_2025 |>
#   filter(is_district, grade_level == "TOTAL",
#          grepl("Stamford", district_name),
#          subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) |>
#   mutate(pct = round(pct * 100, 1)) |>
#   select(subgroup, n_students, pct) |>
#   arrange(desc(pct))
# 
# stamford

## ----stamford-chart-----------------------------------------------------------
# stamford |>
#   mutate(subgroup = forcats::fct_reorder(subgroup, pct)) |>
#   ggplot(aes(x = pct, y = subgroup, fill = subgroup)) +
#   geom_col(show.legend = FALSE) +
#   geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
#   scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
#   scale_fill_brewer(palette = "Set2") +
#   labs(
#     title = "Stamford's Diverse Student Body (2025)",
#     subtitle = "One of the most diverse districts in New England",
#     x = "Percent of Enrollment",
#     y = NULL
#   )

## ----achievement-gap----------------------------------------------------------
# gap_comparison <- enr_2025 |>
#   filter(is_district, grade_level == "TOTAL",
#          grepl("Hartford|Greenwich|Bridgeport|Darien", district_name),
#          subgroup %in% c("total_enrollment", "hispanic", "white", "econ_disadv")) |>
#   select(district_name, subgroup, n_students, pct) |>
#   pivot_wider(names_from = subgroup, values_from = c(n_students, pct))
# 
# gap_comparison

