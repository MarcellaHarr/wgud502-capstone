# Data Analytics Capstone (D502)

*Exploring how geography and climate intersect with victim demographics in homicide data.*

## Overview

This project started with a dataset that caught my attention: FBI Supplementary Homicide Report (SHR) records, paired with U.S. law enforcement agency data and historical weather data spanning over three years (2017 to 2020). The question I kept coming back to was simple. Do factors like where an incident happened, the weather conditions at the time, and the size of the local law enforcement agency have any relationship to the demographics of the victim? That curiosity turned into this capstone.

At its core, this is a predictive analytics project. I'm using logistic regression to see whether weather, geography, and agency population can predict a specific demographic outcome among female homicide victims. Just as much of the work lives in the data itself though, since these are three real world sources that don't line up cleanly out of the box. A lot of this project has been figuring out how to merge them accurately, without quietly losing or duplicating records along the way.

This is my Data Analytics Capstone for WGU's BSDA program, course D502. It's built around three graded deliverables:

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
| Kaggle US State and Territory Latitude and Longitude Data | Latitude and longitude reference data for U.S. states and territories | [Kaggle](https://www.kaggle.com/datasets/marcellaharris/us-state-and-territory-latitudelongitude) | 89,121 |

*Weather and state coordinate data were combined into a single raw file prior to cleaning; more on that in Methodology.*

## Methodology

Merging three independently sourced datasets meant they didn't share a common key out of the box. The homicide data records location as a city or county name, the agency data ties population and sworn officer counts to a specific department, and the weather data is aggregated by state and month. Getting these to line up took more deliberate joining logic than a single merge could handle.

The first pass at merging used a single join key type (`city` and `state`) across all law enforcement agency types. That produced heavy row duplication (one city matching multiple sub-agencies, so each homicide record got copied once per matching agency) and around 45% missingness on agency-level fields. Digging into the raw data showed the real issue: not every agency type is organized around a city. Sheriff's offices are organized by county, state police don't map to a municipality at all, and county police departments are inconsistently labeled across sources.

The fix was to split the homicide data by agency type (`Agentype`), join each subset against the matching slice of agency data using the appropriate key for that type, deduplicate to the highest-population record where multiple sub-agency records shared a key, and then reassemble everything with `bind_rows()`.

| Agency Type | Join Key | Rows | Row Duplication | NA Rate (agency_population) |
|---|---|---|---|---|
| Municipal police | city + state | 141,096 | Resolved via dedup | 14.10% |
| Sheriff | county + state | 41,860 | Resolved via dedup + county name lookup table | 6.61% |
| County police | name-based lookup | 6,237 | Resolved via manual name-correction lookup table | 15.44% |
| Primary state LE | none available | 7,081 | N/A, no city/county key exists | 100% (documented exclusion) |
| Special police | city + state | 450 | Resolved via dedup | 76.89% (genuine non-match, small category) |
| Tribal / Regional police / Primary federal LE | none available | 423 | N/A, no key exists | 100% (documented exclusion) |
| **Total (reassembled)** | | **197,147** | | |

A few specific fixes were needed along the way: an all-caps/whitespace normalization step applied to both sides of every join key, a lookup table correcting a state name typo in the raw homicide data ("Rhodes Island" instead of "Rhode Island"), a lookup table correcting county name formatting mismatches, and a name-correction lookup table for county police departments whose names didn't match cleanly between sources. The agency data also used `-999` as a placeholder for missing numeric values in several columns, which had to be recoded to a true missing value before any completeness analysis, so reported missingness reflects the data accurately.

Once every subset was joined and NA rates were understood, the pieces were combined into a single dataset using only the columns shared across all six subsets (found with `intersect()`), then reassembled with `bind_rows()`. The reassembled dataset holds 197,147 records, and every row has a location value after reassembly, with zero missing. That count comes before the analysis filters. After filtering to female victims for 2017 to 2020 and joining the weather data, the final analytical dataset holds 15,766 records.

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
