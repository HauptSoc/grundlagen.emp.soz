library(shiny2docker)

shiny2docker(path = "./slides/scripts/regression-simple",
             lockfile = "./slides/scripts/regression-simple/renv.lock",
             output = "./slides/scripts/regression-simple/docker")


rsync -avz -e 'ssh' /path/to/local/dir user@remotehost:/path/to/remote/dir

C:\GIT\Grundlagen EmpSoz\slides\scripts\regression-simple

scp -r  'C:/GIT/Grundlagen EmpSoz/slides/scripts/regression-simple' appserver@193.196.36.92: /srv/shiny-server/