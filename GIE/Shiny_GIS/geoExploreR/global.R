require(shiny)
require(shinydashboard)
require(shinyjs)
require(leaflet)
require(ggvis)
require(dplyr)
library(RColorBrewer)
require(raster)
require(gstat)
require(rgdal)
require(Cairo)


data(meuse)
coordinates(meuse) = ~x+y
proj4string(meuse) <- CRS("+init=epsg:28992")
meuse <- spTransform(meuse, CRSobj = CRS("+proj=longlat +datum=WGS84 +no_defs"))

galaxy <- read.csv("/srv/shiny-server/data/inputdata.txt", header=TRUE)
names(galaxy)[1:2] <- c('y','x')
coordinates(galaxy) <- ~x+y

data('jura')
jura <-jura.val[,c(3,4,7:13,5,6)]
names(jura)[1:2] <- c('x','y')
coordinates(jura) <- ~x+y

data(fulmar)
coordinates(fulmar) <- ~x+y
proj4string(fulmar) <- CRS("+init=epsg:32631")
fulmar <- spTransform(fulmar, CRSobj = CRS("+proj=longlat +datum=WGS84 +no_defs"))

datasets <- list(
  'Meuse'=meuse,
  'galaxy'=galaxy,
  'Jura'=jura,
  'Fulmar'=fulmar
)

baselayers <- list(
  'Meuse'='DarkMatter (CartoDB)',
  'galaxy'="Esri.OceanBasemap",
  'Jura'='OpenStreetmap',
  'Fulmar'='OpenStreetmap'
)





