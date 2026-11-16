# Copy each script without its YAML header into a book partial.

#== load the package ==
# (Prabhakaran, 2026)
library(purrr)

#== script for each partial ==
# (Prabhakaran, 2026)
scripts <- data.frame(
  script = c(
    "00_data_cleaning_rebuild.qmd",
    "01_data_exploration.qmd",
    "02_modeling.qmd"
  ),
  partial = c(
    "_cleaning.qmd",
    "_analysis.qmd",
    "_modeling.qmd"
  )
)

#== drop YAML header + write partial ==
# (Prabhakaran, 2026; Ryan, 2024)
scripts %>%
  pwalk(
    function(script, partial) {
      lines <- readLines(
        here::here(
          "scripts",
          script
        )
      )
      yaml_end <- which(
        lines == "---"
      )[2]
      writeLines(
        lines[
          (yaml_end + 1):length(lines)
        ],
        here::here(
          "book",
          partial
        )
      )
    }
  )
