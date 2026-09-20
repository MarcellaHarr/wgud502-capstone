# Data Analytics Capstone (D502)

*Exploring how geography and climate intersect with victim demographics in homicide data.*

## Overview

This project originated from a previous course where I analyzed FBI Supplementary Homicide Report (SHR) data, combined with information from U.S. law enforcement agencies, city and state data, and historical weather records from 2017 to 2020. My goal was to explore whether factors such as incident location, weather at the time, and the size of local law enforcement agencies are related to the victim’s demographics. This curiosity ultimately led to this capstone project.

Essentially, this is a predictive analytics endeavor. I use logistic regression to determine if weather, geography, and agency size can forecast specific demographic patterns among female homicide victims. However, much of the complexity lies in the data itself, since these four sources are disparate and don't align perfectly out of the box. A significant part of the project has involved figuring out how to correctly merge these datasets without losing or duplicating records unnoticed.

This is my Data Analytics Capstone program, course D502. It's built around three graded deliverables:

1. Topic Approval Form (Task 1)
2. Data Analytics Report (Task 2)
3. Data Analytics Presentation (Task 3), which includes a recorded walkthrough of the findings

Beyond the grade, this project is meant to be a real demonstration of end to end analytics work. That means sourcing and cleaning messy real world data, making and documenting defensible methodology decisions, running a predictive model, and communicating the results clearly.

## Research Question

> Among female homicide victims, can weather conditions, agency population, and location predict whether the victim is Black or not Black?

The outcome variable is `victim_racial_construct`, recoded into a binary category: Black versus Not Black. This is limited to female victims only, records with an unknown race are dropped, and smaller race categories (Asian, American Indian/Alaskan Native, Native Hawaiian/Pacific Islander) are collapsed into a single "Other Ethnic" group.

The predictor variables being tested are:

- `temp_2m_avg` (average temperature)
- `relative_humidity_2m_avg` (average relative humidity)
- `rain_sum` (total rainfall)
- `snowfall_sum` (total snowfall)
- `agency_population` (population size of the reporting law enforcement agency)
- `jurisdiction_match` (Within Jurisdiction vs. Surrounding Area, derived from whether the homicide record matched a specific local agency during the pipeline join; a proxy for jurisdiction location, since incident-level coordinates aren't available to compare against agency boundaries directly)

A few variables were intentionally left out as predictors, including offender age, offender gender, offender race, and weapon used, since none of these would be knowable before the outcome itself.

## Data Sources

| Source | Description | Link | Row Count (raw) |
|---|---|---|---|
| Murder Accountability Project (MAP), Supplementary Homicide Report | Incident-level homicide records including victim and offender demographics, weapon, relationship, and circumstance | [murderdata.org](https://www.murderdata.org/p/data-docs.html) | 894,636 |
| HIFLD Local Law Enforcement Locations | Law enforcement agency data including type, location, sworn officer count, and population served | [DataLumos](https://www.datalumos.org/datalumos/project/239493/version/V1/view) | 23,486 |
| Open-Meteo Historical Weather API | Daily weather records, including average temperature, humidity, rainfall, and snowfall | [Open-Meteo](https://open-meteo.com/en/docs/historical-weather-api) | 89,121 |
| Kaggle US State and Territory Latitude and Longitude Data | Latitude and longitude reference data for U.S. states and territories | [Kaggle](https://www.kaggle.com/datasets/tennerimaheshwar/us-state-and-territory-latitude-and-longitude-data) | 89,121 |

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

I also found that several specific fixes were necessary along the way. These included normalizing all-caps and whitespace around join keys, correcting a typo in the raw homicide data's state name from "Rhodes Island" to "Rhode Island," standardizing county name formatting, and updating county police department names to match across sources. Additionally, placeholder values of `-999` in some columns were recoded as missing data to ensure accurate reporting of missingness during analysis.

After joining all subsets and understanding NA rates, the data were combined into a single dataset using only shared columns identified with `intersect()`, then merged with `bind_rows()`. The final dataset contains 197,147 records of female victims with known race across all years, with no missing location data. Filtering to 2017–2020 and adding weather data resulted in a final analytical dataset of 15,766 records.

## Project Structure

```
data/
  raw/
    uncleaned_geojson_df.csv
    uncleaned_map_homicides_df.csv
    uncleaned_weather_2017-2020_v3.csv
  processed/
    homicide_final.parquet                 # final analytical dataset
  weather_homicide_nationalagency_df.parquet   # legacy D497 artifact, unused by this pipeline
docs/                                    # TBD
output/
  dashboard/                             # TBD
  figures/                               # TBD
renv/                                    # renv package library (dependency management, auto-generated)
scripts/
  00_data_cleaning_rebuild.qmd           # primary data cleaning / merge pipeline
  00_data_cleaning_rebuild.html          # rendered output
  01_data_exploration.qmd                # TBD
.Rprofile
.gitignore
renv.lock
```

*`docs/`, `output/dashboard/`, `output/figures/`, and `01_data_exploration.qmd` are placeholders for now and will fill in as the analysis and reporting phases progress.*

## Tools & Tech Stack

| Tool | Purpose |
|---|---|
| Positron | IDE for writing and running the project |
| R (4.6.1) | Core language for data cleaning, joins, and analysis |
| Quarto (1.7.33) | Notebook format for the cleaning pipeline (`.qmd`), rendering to HTML |
| renv (1.2.3) | Dependency and package version management |
| git | Version control (local only, no remote yet) |
| dplyr | Data wrangling: filtering, joins, mutating, grouping |
| tidyr | Reshaping and tidying data |
| stringr | String manipulation and pattern matching |
| stringi | Underlying string operations (used alongside stringr) |
| here | Reliable, project-relative file paths |
| arrow | Reading/writing the `.parquet` dataset |
| ggplot2 | Data visualization |
| rmarkdown | Report rendering support |
| lubridate | Date and time handling |
| readr | Reading CSV files |

## Setup / Getting Started

This repo is currently local-only (no remote configured yet), so it isn't set up for others to clone and run. A few other things to know if you're looking at the code:

- **Raw data isn't included.** The files in `data/raw/` are gitignored due to size. Sources and links are listed above under Data Sources.
- **Dependencies are managed with `renv`.** The lockfile (`renv.lock`) tracks package versions used in this project.
- **The main entry point is `scripts/00_data_cleaning_rebuild.qmd`.** This is where the raw data gets cleaned, joined, and combined into the final analytical dataset.

*Once a remote and reproducible setup path exist, this section will be updated with actual clone/restore/render instructions.*

## Deliverables

This capstone is graded across three sequential Performance Assessment tasks. Task 1 must be submitted before Tasks 2 and 3 can proceed.

| Task | Description | Status |
|---|---|---|
| Task 1: Topic Approval Form | Proposes the research question, data sources, and methodology for review | Passed (Sep 15) |
| Task 2: Data Analytics Report | Full written report covering data collection, extraction/preparation, and analysis methods | Not started |
| Task 3: Data Analytics Presentation | Written report plus a recorded presentation of findings | Not started |

## Take Aways

*In progress. Will be filled in once the analysis and modeling are complete.*

## Conclusion

*In progress. Will be filled in once the project is finished.*
