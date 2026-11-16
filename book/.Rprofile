# Turn on the project's renv library when R starts in book/.

#== set project's activate.R ==
Sys.setenv(
  RENV_PROJECT = normalizePath("..")
)
source(
  "../renv/activate.R"
)

#== set project root for here() ==
# (Monteagudo, 2024)
here::i_am("book/_quarto.yml")
