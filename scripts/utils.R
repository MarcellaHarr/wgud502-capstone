#=== ggplot-best-practice ===
# # Set a reusable theme for consistent text styling.
#===============================
#== custom theme ==
ggplot_theme <- theme(
  #== title ==
  plot.title = element_text(
    hjust = 0.5,
    face = "bold",
    size = 18
  ),
  #== subtitle ==
  plot.subtitle = element_text(
    hjust = 0.5,
    size = 14
  ),
  #== caption ==
  plot.caption = element_text(
    hjust = 1,
    size = 10,
    color = "gray"
  ),
  axis.title.x = element_text(
    margin = margin(
      t = 15
    )
  )
)

#=== load-data-fx code chunk ===
# Create a function to load raw files and confirm row counts.
#===============================

#== function computation ==
# (Olumide, 2025; Prabhakaran, 2026; Buck, 2025)
load_raw_data <- function(
  homicide_path = here::here(
    "data",
    "raw",
    "uncleaned_map_homicides_df.csv"
  ),
  geojson_path = here::here(
    "data",
    "raw",
    "uncleaned_geojson_df.csv"
  ),
  weather_path = here::here(
    "data",
    "raw",
    "uncleaned_weather_2017-2020_v3.csv"
  ),
  homicide_rows = 894636,
  geojson_rows = 23486,
  weather_rows = 89121
) {
  #== homicide file ==
  # (Wei, 2026; Olumide, 2025; Prabhakaran, 2026)
  homicide_raw <- readr::read_csv(homicide_path)
  # verify record amount and stop loading if incorrect
  stopifnot(
    nrow(
      homicide_raw
    ) ==
      homicide_rows
  )

  #== geojson/agency file ==
  # (Wei, 2026; Olumide, 2025; Prabhakaran, 2026)
  geojson_raw <- readr::read_csv(geojson_path)
  # verify record amount and stop loading if incorrect
  stopifnot(
    nrow(
      geojson_raw
    ) ==
      geojson_rows
  )

  #== weather file ==
  # (Wei, 2026; Olumide, 2025; Prabhakaran, 2026)
  weather_raw <- readr::read_csv(weather_path)
  # verify record amount and stop loading if incorrect
  stopifnot(
    nrow(
      weather_raw
    ) ==
      weather_rows
  )

  #== view all record amount ==
  cat("All raw row counts confirmed.\n")

  #== return all three datasets together in a list ==
  # (Olumide, 2025; Prabhakaran, 2026; Oltman, 2022)
  return(
    list(
      homicide = homicide_raw,
      geojson = geojson_raw,
      weather = weather_raw
    )
  )
}

#=== call-name-fx code chunk ===
# Create a function to list the dataset columns.
#===============================

#== column display function ==
# (Olumide, 2025; Prabhakaran, 2026; Buck, 2025)
column_list <- function(
  data1 = homicide_df,
  data2 = geojson_df,
  data3 = weather_df
) {
  #== extract homicide dataset ==
  dataset_1 <- data1 %>%
    # (Prabhakaran, 2026; Errickson, 2017; GeeksforGeeks, 2025)
    names()

  #== extract geojson dataset ==
  dataset_2 <- data2 %>%
    # (Prabhakaran, 2026; Errickson, 2017; GeeksforGeeks, 2025)
    names()

  #== extract weather dataset ==
  dataset_3 <- data3 %>%
    # (Prabhakaran, 2026; Errickson, 2017; GeeksforGeeks, 2025)
    names()

  #== view results ==
  cat("All datasets returned.\n")

  #== return all dataset columns ==
  # (Olumide, 2025; Prabhakaran, 2026; Oltman, 2022)
  return(
    list(
      homicide_list = dataset_1,
      geojson_list = dataset_2,
      weather_list = dataset_3
    )
  )
}


#=== col-count-fx code chunk ===
# Count the total number of columns to confirm datasets' width and structure.
#===============================

#== column count computation ==
# (Olumide, 2025; Prabhakaran, 2026; Buck, 2025)
check_column_counts <- function(
  data1 = homicide_renamed,
  data2 = geojson_renamed,
  data3 = weather_renamed
) {
  #== view first dataset column count ==
  cols_1 <- ncol(data1)

  #== view second dataset column count ==
  cols_2 <- ncol(data2)

  #== view third dataset column count ==
  cols_3 <- ncol(data3)

  #== view results ==
  cat("Homicide, Law Enforcement, and Weather columns returned.\n")

  #== return all column counts ==
  # (Olumide, 2025; Prabhakaran, 2026; Oltman, 2022)
  return(list(
    homicide_cols = cols_1,
    geojson_cols = cols_2,
    weather_cols = cols_3
  ))
}

#=== df-three-col-count-fx code chunk ===
# Count unique values for three columns in a dataset.
#===============================

#== column check function ==
three_col_check <- function(
  data,
  col1 = VicEthnic,
  col2 = VicRace,
  col3 = VicSex
) {
  #== view first column counts ==
  counts_1 <- data %>%
    count(
      {{ col1 }}
    )

  #== view second column counts ==
  counts_2 <- data %>%
    count(
      {{ col2 }}
    )

  #== view third column counts ==
  counts_3 <- data %>%
    count(
      {{ col3 }}
    )

  #== view results ==
  cat("The dataframe's three columns returned.\n")

  #== return all summaries ==
  # (Olumide, 2025; Prabhakaran, 2026; Oltman, 2022)
  return(
    list(
      first_summary = counts_1,
      second_summary = counts_2,
      third_summary = counts_3
    )
  )
}

#=== combined-row-count-fx code chunk ===
# Count the sum of rows from 2+ objects, get their names, and display as DF.
#===============================

#== check total row counts ==
# (Parry, 2023; Cotton, 2011)
total_rows <- function(...) {
  #== get all objects ==
  object_list <- list(...)

  #== get object names ==
  object_names <- names(
    object_list
  )

  #== console message ==
  cat("Total row counts for each object are: \n\n")

  #== call a fx + apply to the list ==
  # (aL3xa, 2011; Prabhakaran, 2026)
  sapply(object_list, nrow)
}

#=== agg-table-fx code chunk ===
# Pulls different calculated results and displays them in a single table.
#===============================

#== build pretty table ==
# (Parry, 2023; Cotton, 2011)
pretty_summary <- function(
  main_title = "",
  sub_title = "",
  ...
) {
  #== get all aggreggated outputs ==
  console_results <- list(...)

  #== convert results into a named dataframe ==
  # (Lettry, 2024)
  summary_dataframe <- tibble::enframe(
    console_results,
    name = "Metric",
    value = "Value"
  )

  #== prettify summary table ==
  summary_dataframe %>%
    # (Muldon, 2021)
    gt() %>%
    tab_header(
      title = md(main_title),
      subtitle = md(sub_title)
    )
}


#=== calibration-curve-fx code chunk ===
# Create the calibration data and table for the full model.
#===============================

#== bin the predictions ==
# (Wong, 2026)
calibration_data <- function(
  pred,
  y,
  model_name,
  n_bins = 10
) {
  tibble::tibble(
    pred = pred,
    y = y
  ) %>%
    mutate(
      bin = ntile(
        pred,
        n_bins
      )
    ) %>%
    group_by(
      bin
    ) %>%
    summarise(
      mean_pred = mean(
        pred
      ),
      observed_rate = mean(
        y
      ),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(
      model = model_name
    )
}
