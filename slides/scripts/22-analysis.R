library(tidyverse)

my_packages <-
  installed.packages() |>
  as_tibble() |>
  pull(Package)

install.packages(my_packages)