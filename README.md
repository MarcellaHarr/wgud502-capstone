# Data Analytics Capstone (D502)

*Exploring how geography and climate intersect with victim demographics in homicide data.*

## Overview

This project originated from a previous course where I analyzed FBI Supplementary Homicide Report (SHR) data, combined with information from U.S. law enforcement agencies, city and state data, and historical weather records from 2017 to 2020. My goal was to explore whether factors such as incident location, weather at the time, and the size of local law enforcement agencies are related to the victim’s demographics. This curiosity ultimately led to this capstone project.

Essentially, this is a predictive analytics endeavor. I use logistic regression to determine if weather, geography, and agency size can forecast specific demographic patterns among female homicide victims. However, much of the complexity lies in the data itself, since these four sources are disparate and don't align perfectly out of the box. A significant part of the project has involved figuring out how to correctly merge these datasets without losing or duplicating records unnoticed.

This is my Data Analytics Capstone program, course D502. It's built around three graded deliverables:

1. Topic Approval Form (Task 1)
2. Project Proposal (Task 2)
3. Project Report (Task 3), which includes a recorded Panopto presentation of the findings

Beyond the grade, this project is meant to be a real demonstration of end to end analytics work. That means sourcing and cleaning messy real world data, making and documenting defensible methodology decisions, running a predictive model, and communicating the results clearly.

## Research Question

> Among female homicide victims, can weather conditions, agency population, and location predict whether the victim is Black or not Black?

The outcome variable is `victim_racial_construct`, recoded into a binary category: Black versus Not Black. This is limited to female victims only, records with an unknown race are dropped, and smaller race categories (Asian, American Indian/Alaskan Native, Native Hawaiian/Pacific Islander) are collapsed into a single "Other Ethnic" group.

The predictor variables being tested are:

- `temp_2m_avg` (average temperature)
- `relative_humidity_2m_avg` (average relative humidity)
- `rain_sum` (total rainfall)
- `snowfall_sum` (total snowfall)
- `agency_population` (population size of the reporting law enforcement agency; missing values are filled with the median learned from the training set)
- `jurisdiction_match` (Within Jurisdiction vs. Surrounding Area, derived from whether the homicide record matched a specific local agency during the pipeline join; a proxy for jurisdiction location, since incident-level coordinates aren't available to compare against agency boundaries directly)

A few variables were intentionally left out as predictors, including offender age, offender gender, offender race, and weapon used, since none of these would be knowable before the outcome itself.

## Data Sources

| Source | Description | Link | Row Count (raw) |
|---|---|---|---|
| Murder Accountability Project (MAP), Supplementary Homicide Report | Incident-level homicide records including victim and offender demographics, weapon, relationship, and circumstance | [murderdata.org](https://www.murderdata.org/p/data-docs.html) | 894,636 |
| HIFLD Local Law Enforcement Locations | Law enforcement agency data including type, location, sworn officer count, and population served | [DataLumos](https://www.datalumos.org/datalumos/project/239493/version/V1/view) | 23,486 |
| Open-Meteo Historical Weather API | Daily weather records, including average temperature, humidity, rainfall, and snowfall | [Open-Meteo](https://open-meteo.com/en/docs/historical-weather-api) | 89,121 |
| Kaggle US State and Territory Latitude and Longitude Data | Latitude and longitude reference data for U.S. states and territories | [Kaggle](https://www.kaggle.com/datasets/tennerimaheshwar/us-state-and-territory-latitude-and-longitude-data) | 61 |

*Weather and state coordinate data were combined into a single raw file prior to cleaning; more on that in Methodology.*

## Methodology

Merging four independent datasets was challenging due to the absence of a common key. The homicide data records locations by city or county, while the law enforcement data links population and officer counts to departments and aligns it with weather data, which is aggregated by state and month. Achieving alignment required complex join logic beyond simple merges.

For my initial approach, I used a combined 'city' and 'state' key across all agencies, but this led to significant row duplication and about 45% missing agency data. Further analysis revealed the main issue was that agency structures differed: 
- Sheriff's offices are county-based, 
- state police are not municipality-specific, and 
- county police departments have inconsistent labels.

The solution was to split the homicide data by agency type, join each subset with the relevant agency data using appropriate keys, deduplicate by retaining the highest-population record when multiple sub-agencies shared a key, and then recombine everything with `bind_rows()`.

| Agency Type | Join Key | Rows | Row Duplication | NA Rate (agency_population) |
|---|---|---|---|---|
| Municipal police | city + state | 141,096 | Resolved via dedup | 14.10% |
| Sheriff | county + state | 41,860 | Resolved via dedup + county name lookup table | 6.61% |
| County police | name-based lookup | 6,237 | Resolved via manual name-correction lookup table | 15.44% |
| Primary state LE | none available | 7,081 | N/A, no city/county key exists | 100% (documented exclusion) |
| Special police | city + state | 450 | Resolved via dedup | 76.89% (genuine non-match, small category) |
| Tribal / Regional police / Primary federal LE | none available | 423 | N/A, no key exists | 100% (documented exclusion) |
| **Total (reassembled)** | | **197,147** | | |

I also found that several specific fixes were necessary along the way. These included normalizing all-caps and whitespace around join keys, correcting a typo in the raw homicide data's state name from "Rhodes Island" to "Rhode Island," standardizing county name formatting, and updating county police department names to match across sources. 

Additionally, placeholder values of `-999` in some columns were recoded as missing data to ensure accurate reporting of missingness during analysis. Finally, eleven county names were corrected to match the U.S. Census Bureau's 2020 spellings (for example, *De Kalb, GA* to *DeKalb, GA*), and 43 Richmond city and 9 Roanoke city records were moved from their county names to their independent cities, so every record could be placed on the county map.

After joining all subsets and understanding NA rates, the data were combined into a single dataset using only shared columns identified with `intersect()`, then merged with `bind_rows()`. The final dataset contains 197,147 records of female victims with known race across all years, with no missing location data. 

Filtering to records from 2017 through 2020 and adding the monthly weather data resulted in a final analytical dataset of 15,766 records, saved as `homicide_final.parquet`. A copy with the added *jurisdiction_match* column categories (Within Jurisdiction or Surrounding Area) is saved as `homicide_modeling.parquet` for the exploration and modeling scripts.

## Project Structure

```
data/                                      # gitignored, not on GitHub
  raw/
    uncleaned_geojson_df.csv               # law enforcement agency data
    uncleaned_map_homicides_df.csv         # homicide records
    uncleaned_weather_2017-2020_v3.csv     # weather with state coordinates
  processed/
    homicide_final.parquet                 # final cleaned homicide dataset (15,766 records, 34 columns)
    homicide_modeling.parquet              # modeling dataset (15,766 records, 35 columns)
output/
  figures/
    fig_1.png                              # victims by race (bar chart)
    fig_2.png                              # predictors by victim race (box plots)
    fig_3.png                              # victim race by jurisdiction group (county map)
    fig_4.png                              # correlation between predictors (heatmap)
    fig_5.png                              # Black proportion by state (bar chart)
    fig_6.png                              # calibration curve
    fig_7.png                              # scaled odds ratios (forest plot)
    fig_8.png                              # practical-significance changes (paired plot)
renv/                                      # renv setup files (package library is gitignored)
scripts/
  00_data_cleaning_rebuild.qmd             # data cleaning and merge pipeline
  01_data_exploration.qmd                  # exploratory analysis (Figs. 1 to 5)
  02_modeling.qmd                          # logistic regression, evaluation, and model visuals (Figs. 6 to 8)
  utils.R                                  # helper functions and shared ggplot theme
  references.bib                           # sources cited in the scripts
  apa-numeric-superscript-brackets.csl     # citation style for the rendered reports
.Rprofile
.gitignore
README.md
renv.lock
```

*The `data/` folder and the rendered `.html` reports are gitignored, so they aren't on GitHub. Links to the raw data are listed under Data Sources.*

## Tools & Tech Stack

| Tool | Purpose |
|---|---|
| Positron (2026.09.1) | IDE for writing and running the project |
| R (4.6.1) | Core language for cleaning, joining, exploring, and modeling the data |
| Quarto (1.7.33) | Notebook format for the three scripts (`.qmd`), rendering to HTML |
| renv (1.2.3) | Dependency and package version management |
| git and GitHub | Version control, hosted at [MarcellaHarr/wgud502-capstone](https://github.com/MarcellaHarr/wgud502-capstone) |
| here (1.0.2) | Reliable, project-relative file paths |
| readr (2.2.0) | Reading CSV files |
| arrow (24.0.0) | Reading and writing the `.parquet` datasets |
| dplyr (1.2.1) | Data wrangling: filtering, joins, mutating, grouping |
| tidyr (1.3.2) | Reshaping and tidying data |
| tibble (3.3.1) | Building small tables in the helper functions |
| stringr (1.6.0) | String manipulation and pattern matching |
| lubridate (1.9.5) | Date and time handling |
| gt (1.4.0) | Formatted summary and results tables |
| ggplot2 (4.0.3) | Data visualization (Figs. 1 to 7) |
| ggpubr (1.0.0) | Paired plot of the practical-significance changes (Fig. 8) |
| sf (1.1-3) | Joining record counts to county shapes and finding county center points |
| lwgeom (0.2-17) | Geometry functions that support sf |
| tigris (2.3.0) | 2020 U.S. Census state and county shapes |
| tidymodels (1.5.0) | Modeling framework: data split, recipe, logistic regression, workflow, and metrics |
| broom (1.0.13) | Coefficient and odds-ratio tables from the fitted model |
| rmarkdown (2.31) | Report rendering support |
| sessioninfo (1.2.4) | Recording package versions at the end of each script |
| osmdata (0.4.1) | Loaded in `01_data_exploration.qmd` for a planned street-level map; not used in the final analysis |
| pROC (1.19.1) | Loaded in `02_modeling.qmd` for a planned ROC curve; not used in the final analysis |

## Setup / Getting Started

To run this project on your own machine:

1. **Clone the repo.**
   ```
   git clone https://github.com/MarcellaHarr/wgud502-capstone.git
   ```
2. **Restore the packages.** Open the project folder in Positron (or RStudio), then run this in the R Console to install the exact package versions recorded in `renv.lock`:
   ```r
   renv::restore()
   ```
3. **Add the raw data.** The raw files aren’t included in the repo. They were downloaded and combined in an earlier course from the sources listed under Data Sources, so the scripts expect the three file names shown under Project Structure in `data/raw/`.
4. **Run the scripts in order.** `00_data_cleaning_rebuild.qmd` saves the two Parquet files that the other two scripts read, so run it first, then `01_data_exploration.qmd`, then `02_modeling.qmd`. Each one can be rendered from the Terminal:
   ```
   quarto render scripts/00_data_cleaning_rebuild.qmd
   quarto render scripts/01_data_exploration.qmd
   quarto render scripts/02_modeling.qmd
   ```
5. **Have an internet connection for the map.** `01_data_exploration.qmd` downloads the 2020 Census state and county shapes through tigris the first time it runs, then reuses the saved copy.

## Deliverables

This capstone is graded across three sequential Performance Assessment tasks. Task 1 must be submitted before Tasks 2 and 3 can proceed.

| Task | Description | Status |
|---|---|---|
| Task 1: Topic Approval Form | Proposes the research question, data sources, and methodology for review | Passed (Sep 15) |
| Task 2: Project Proposal | Written proposal covering the research question, project plan, analysis design, and data description | Passed on first attempt (Nov 12) |
| Task 3: Project Report | Final report of the completed analysis and results, plus a recorded Panopto presentation | In progress |

## Take Aways

- The hardest part of this project was matching each homicide to its law enforcement agency, since the four sources had no shared key.
- All six predictors were statistically significant, but only relative humidity was large enough to matter in practice, changing the predicted proportion of Black victims by more than 5.5 percentage points.
- My model ranked Black victims above Not Black victims better than chance (ROC AUC 0.647), but its accuracy (64.0%) still fell short of the 64.3% always-"Not Black" baseline.
- Odds ratios are per one unit, so I scaled the predictors, which are measured in people, degrees, and inches, to the same 1st-to-3rd-quartile range before comparing them on one plot.

## Conclusion

Among female homicide victims from 2017 through 2020, all six conditions were linked to the victim being Black, with every 95% confidence interval excluding 1 at an alpha of .05. However, the model’s accuracy (64.0%) fell just short of the 64.3% always-“Not Black” baseline, so together these conditions weren’t strong enough to classify individual victims. Only relative humidity changed the predicted proportion of Black victims by more than the 5.5-point cutoff, rising from 33.2% to 41.2%. These results show association, not cause, so public health agencies and violence prevention programs could use them to plan outreach for groups and places, not to predict any one victim’s race. Future work could add stronger predictors, such as county-level demographics and income, and use weather measured closer to where each homicide happened instead of statewide monthly averages.
