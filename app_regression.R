library(shiny2docker)

shiny2docker(path = "./slides/scripts/regression-simple",
             lockfile = "./slides/scripts/regression-simple/renv.lock",
             output = "./slides/scripts/regression-simple/docker")
